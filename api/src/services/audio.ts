import { createHmac, randomBytes } from "node:crypto";
import { existsSync, mkdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { v4 as uuid } from "uuid";
import { config } from "../config.js";
import { getDb } from "../db/index.js";
import { ApiError } from "../lib/errors.js";
import { findUserById } from "./user.js";

const UPLOAD_TTL_MS = 15 * 60 * 1000;
const DOWNLOAD_TTL_MS = 60 * 60 * 1000;

interface PendingUpload {
  clipId: string;
  userId: string;
  key: string;
  expiresAt: number;
}

const pendingUploads = new Map<string, PendingUpload>();

function requirePremium(userId: string): void {
  const user = findUserById(userId);
  if (!user?.is_premium) {
    throw new ApiError("PREMIUM_REQUIRED", "Cloud audio requires Premium subscription", 403);
  }
}

function signDownloadToken(clipId: string, userId: string, exp: number): string {
  const payload = `${clipId}:${userId}:${exp}`;
  const sig = createHmac("sha256", config.jwtSecret).update(payload).digest("hex");
  return Buffer.from(`${payload}:${sig}`).toString("base64url");
}

function verifyDownloadToken(token: string): { clipId: string; userId: string } | null {
  try {
    const decoded = Buffer.from(token, "base64url").toString("utf-8");
    const parts = decoded.split(":");
    if (parts.length !== 4) return null;
    const [clipId, userId, expStr, sig] = parts;
    const exp = Number(expStr);
    if (Date.now() > exp) return null;
    const expected = createHmac("sha256", config.jwtSecret).update(`${clipId}:${userId}:${exp}`).digest("hex");
    if (sig !== expected) return null;
    return { clipId, userId };
  } catch {
    return null;
  }
}

export function createUploadUrl(userId: string, clipId?: string, contentType = "audio/mpeg"): {
  uploadUrl: string;
  clipId: string;
  uploadId: string;
  expiresAt: string;
} {
  requirePremium(userId);
  const id = clipId ?? uuid();
  const uploadId = uuid();
  const key = `${userId}/${id}.audio`;
  const expiresAt = Date.now() + UPLOAD_TTL_MS;

  pendingUploads.set(uploadId, { clipId: id, userId, key, expiresAt });

  const uploadUrl = `${config.baseUrl}/audio/upload/${uploadId}`;

  return {
    uploadUrl,
    clipId: id,
    uploadId,
    expiresAt: new Date(expiresAt).toISOString(),
  };
}

export function receiveUpload(uploadId: string, body: ArrayBuffer): { clipId: string; size: number } {
  const pending = pendingUploads.get(uploadId);
  if (!pending || Date.now() > pending.expiresAt) {
    throw new ApiError("UPLOAD_EXPIRED", "Upload URL expired or invalid", 410);
  }
  pendingUploads.delete(uploadId);

  const dir = join(config.uploadDir, pending.userId);
  mkdirSync(dir, { recursive: true });
  const filePath = join(dir, `${pending.clipId}.audio`);
  const buffer = Buffer.from(body);
  writeFileSync(filePath, buffer);

  const ts = new Date().toISOString();
  const existing = getDb()
    .prepare("SELECT id FROM clips WHERE id = ? AND user_id = ?")
    .get(pending.clipId, pending.userId);
  if (existing) {
    getDb()
      .prepare("UPDATE clips SET cloud_key = ?, updated_at = ? WHERE id = ? AND user_id = ?")
      .run(pending.key, ts, pending.clipId, pending.userId);
  } else {
    getDb()
      .prepare(
        `INSERT INTO clips (id, user_id, payload, updated_at, cloud_key)
         VALUES (?, ?, '{}', ?, ?)`,
      )
      .run(pending.clipId, pending.userId, ts, pending.key);
  }

  return { clipId: pending.clipId, size: buffer.length };
}

export function confirmUpload(userId: string, clipId: string): { confirmed: boolean } {
  requirePremium(userId);
  const row = getDb()
    .prepare("SELECT cloud_key FROM clips WHERE id = ? AND user_id = ? AND deleted_at IS NULL")
    .get(clipId, userId) as { cloud_key: string | null } | undefined;
  if (!row?.cloud_key) {
    throw new ApiError("CLIP_NOT_FOUND", "Clip not found or upload incomplete", 404);
  }
  const filePath = join(config.uploadDir, userId, `${clipId}.audio`);
  if (!existsSync(filePath)) {
    throw new ApiError("UPLOAD_INCOMPLETE", "Audio file not found on server", 400);
  }
  return { confirmed: true };
}

export function getDownloadUrl(userId: string, clipId: string): { downloadUrl: string; expiresAt: string } {
  requirePremium(userId);
  const row = getDb()
    .prepare("SELECT cloud_key FROM clips WHERE id = ? AND user_id = ? AND deleted_at IS NULL")
    .get(clipId, userId) as { cloud_key: string | null } | undefined;
  if (!row?.cloud_key) {
    throw new ApiError("CLIP_NOT_FOUND", "Clip has no cloud copy", 404);
  }
  const filePath = join(config.uploadDir, userId, `${clipId}.audio`);
  if (!existsSync(filePath)) {
    throw new ApiError("CLIP_NOT_FOUND", "Audio file missing", 404);
  }

  const exp = Date.now() + DOWNLOAD_TTL_MS;
  const token = signDownloadToken(clipId, userId, exp);
  return {
    downloadUrl: `${config.baseUrl}/audio/stream/${token}`,
    expiresAt: new Date(exp).toISOString(),
  };
}

export function streamDownload(token: string): { filePath: string; userId: string; clipId: string } | null {
  const verified = verifyDownloadToken(token);
  if (!verified) return null;
  const filePath = join(config.uploadDir, verified.userId, `${verified.clipId}.audio`);
  if (!existsSync(filePath)) return null;
  return { filePath, ...verified };
}

export function deleteCloudAudio(userId: string, clipId: string): void {
  requirePremium(userId);
  const filePath = join(config.uploadDir, userId, `${clipId}.audio`);
  if (existsSync(filePath)) unlinkSync(filePath);
  getDb()
    .prepare("UPDATE clips SET cloud_key = NULL, updated_at = ? WHERE id = ? AND user_id = ?")
    .run(new Date().toISOString(), clipId, userId);
}

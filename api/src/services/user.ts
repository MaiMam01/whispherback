import bcrypt from "bcryptjs";
import { v4 as uuid } from "uuid";
import { getDb } from "../db/index.js";
import { ApiError } from "../lib/errors.js";

export interface UserRow {
  id: string;
  email: string;
  password_hash: string | null;
  google_sub: string | null;
  is_premium: number;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

const now = () => new Date().toISOString();

export function findUserByEmail(email: string): UserRow | undefined {
  return getDb().prepare("SELECT * FROM users WHERE email = ? AND deleted_at IS NULL").get(email.toLowerCase()) as
    | UserRow
    | undefined;
}

export function findUserById(id: string): UserRow | undefined {
  return getDb().prepare("SELECT * FROM users WHERE id = ? AND deleted_at IS NULL").get(id) as UserRow | undefined;
}

export function createUser(email: string, password: string): UserRow {
  const existing = findUserByEmail(email);
  if (existing) throw new ApiError("EMAIL_EXISTS", "Email already registered", 409);
  const id = uuid();
  const ts = now();
  const hash = bcrypt.hashSync(password, 10);
  getDb()
    .prepare(
      `INSERT INTO users (id, email, password_hash, is_premium, created_at, updated_at)
       VALUES (?, ?, ?, 0, ?, ?)`,
    )
    .run(id, email.toLowerCase(), hash, ts, ts);
  return findUserById(id)!;
}

export function verifyPassword(user: UserRow, password: string): boolean {
  if (!user.password_hash) return false;
  return bcrypt.compareSync(password, user.password_hash);
}

export function findOrCreateGoogleUser(email: string, googleSub: string): UserRow {
  const byGoogle = getDb()
    .prepare("SELECT * FROM users WHERE google_sub = ? AND deleted_at IS NULL")
    .get(googleSub) as UserRow | undefined;
  if (byGoogle) return byGoogle;

  const byEmail = findUserByEmail(email);
  if (byEmail) {
    getDb().prepare("UPDATE users SET google_sub = ?, updated_at = ? WHERE id = ?").run(googleSub, now(), byEmail.id);
    return findUserById(byEmail.id)!;
  }

  const id = uuid();
  const ts = now();
  getDb()
    .prepare(
      `INSERT INTO users (id, email, google_sub, is_premium, created_at, updated_at)
       VALUES (?, ?, ?, 0, ?, ?)`,
    )
    .run(id, email.toLowerCase(), googleSub, ts, ts);
  return findUserById(id)!;
}

export function softDeleteUser(userId: string): void {
  const ts = now();
  getDb().prepare("UPDATE users SET deleted_at = ?, updated_at = ? WHERE id = ?").run(ts, ts, userId);
}

export function setPremium(userId: string, isPremium: boolean): UserRow | undefined {
  const ts = now();
  getDb()
    .prepare("UPDATE users SET is_premium = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL")
    .run(isPremium ? 1 : 0, ts, userId);
  return findUserById(userId);
}

export function listUsers(limit: number, offset: number): { users: UserRow[]; total: number } {
  const total = (getDb().prepare("SELECT COUNT(*) as c FROM users WHERE deleted_at IS NULL").get() as { c: number }).c;
  const users = getDb()
    .prepare("SELECT * FROM users WHERE deleted_at IS NULL ORDER BY created_at DESC LIMIT ? OFFSET ?")
    .all(limit, offset) as UserRow[];
  return { users, total };
}

export function upsertDevice(userId: string, deviceId: string): void {
  const ts = now();
  const existing = getDb().prepare("SELECT id FROM devices WHERE id = ?").get(deviceId);
  if (existing) {
    getDb().prepare("UPDATE devices SET user_id = ?, last_sync_at = ? WHERE id = ?").run(userId, ts, deviceId);
  } else {
    getDb().prepare("INSERT INTO devices (id, user_id, last_sync_at, created_at) VALUES (?, ?, ?, ?)").run(deviceId, userId, ts, ts);
  }
}

export function updateDeviceSync(userId: string, deviceId: string): void {
  upsertDevice(userId, deviceId);
  getDb().prepare("UPDATE devices SET last_sync_at = ? WHERE id = ? AND user_id = ?").run(now(), deviceId, userId);
}

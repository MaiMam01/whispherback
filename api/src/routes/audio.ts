import { readFileSync } from "node:fs";
import { Hono } from "hono";
import { z } from "zod";
import { bearerAuth, type AuthVariables } from "../middleware/auth.js";
import {
  confirmUpload,
  createUploadUrl,
  deleteCloudAudio,
  getDownloadUrl,
  receiveUpload,
  streamDownload,
} from "../services/audio.js";

const uploadUrlSchema = z.object({
  clipId: z.string().uuid().optional(),
  contentType: z.string().default("audio/mpeg"),
});

const confirmSchema = z.object({
  clipId: z.string().uuid(),
});

export const audioRoutes = new Hono<{ Variables: AuthVariables }>();

audioRoutes.post("/upload-url", bearerAuth, async (c) => {
  const userId = c.get("userId");
  const body = uploadUrlSchema.parse(await c.req.json().catch(() => ({})));
  const result = createUploadUrl(userId, body.clipId, body.contentType);
  return c.json(result);
});

audioRoutes.put("/upload/:uploadId", async (c) => {
  const uploadId = c.req.param("uploadId");
  const body = await c.req.arrayBuffer();
  const result = receiveUpload(uploadId, body);
  return c.json({ ok: true, ...result });
});

audioRoutes.post("/confirm", bearerAuth, async (c) => {
  const userId = c.get("userId");
  const body = confirmSchema.parse(await c.req.json());
  const result = confirmUpload(userId, body.clipId);
  return c.json(result);
});

audioRoutes.get("/download-url/:clipId", bearerAuth, async (c) => {
  const userId = c.get("userId");
  const clipId = c.req.param("clipId");
  const result = getDownloadUrl(userId, clipId);
  return c.json(result);
});

audioRoutes.get("/stream/:token", async (c) => {
  const token = c.req.param("token");
  const stream = streamDownload(token);
  if (!stream) {
    return c.json({ error: { code: "LINK_EXPIRED", message: "Download link expired or invalid" } }, 410);
  }
  const data = readFileSync(stream.filePath);
  return new Response(data, {
    headers: {
      "Content-Type": "audio/mpeg",
      "Content-Length": String(data.length),
      "Cache-Control": "private, max-age=3600",
    },
  });
});

audioRoutes.delete("/:clipId", bearerAuth, async (c) => {
  const userId = c.get("userId");
  const clipId = c.req.param("clipId");
  deleteCloudAudio(userId, clipId);
  return c.json({ deleted: true });
});

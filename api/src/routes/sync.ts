import { Hono } from "hono";
import { z } from "zod";
import { bearerAuth, type AuthVariables } from "../middleware/auth.js";
import { pullChanges, pushChanges, getSyncStatus } from "../services/sync.js";
import { updateDeviceSync } from "../services/user.js";
import type { PushPayload } from "../types.js";

const pushSchema = z.object({
  deviceId: z.string().uuid(),
  timestamp: z.string(),
  playlists: z.array(z.record(z.unknown())),
  clips: z.array(z.record(z.unknown())),
  schedules: z.array(z.record(z.unknown())),
  deletedIds: z.object({
    playlists: z.array(z.string()).default([]),
    clips: z.array(z.string()).default([]),
    schedules: z.array(z.string()).default([]),
  }),
});

export const syncRoutes = new Hono<{ Variables: AuthVariables }>();

syncRoutes.use("*", bearerAuth);

syncRoutes.get("/pull", async (c) => {
  const userId = c.get("userId");
  const since = c.req.query("since") || undefined;
  const data = pullChanges(userId, since);
  return c.json(data);
});

syncRoutes.post("/push", async (c) => {
  const userId = c.get("userId");
  const raw = pushSchema.parse(await c.req.json());
  const payload: PushPayload = {
    deviceId: raw.deviceId,
    timestamp: raw.timestamp,
    playlists: raw.playlists as PushPayload["playlists"],
    clips: raw.clips as PushPayload["clips"],
    schedules: raw.schedules as PushPayload["schedules"],
    deletedIds: raw.deletedIds,
  };
  const result = pushChanges(userId, payload);
  updateDeviceSync(userId, payload.deviceId);
  return c.json(result);
});

syncRoutes.get("/status", async (c) => {
  const userId = c.get("userId");
  const status = getSyncStatus(userId);
  return c.json(status);
});

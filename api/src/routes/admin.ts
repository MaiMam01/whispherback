import { Hono } from "hono";
import { z } from "zod";
import { adminAuth } from "../middleware/admin.js";
import { getDb } from "../db/index.js";
import { listUsers, setPremium } from "../services/user.js";
import { ApiError } from "../lib/errors.js";

export const adminRoutes = new Hono();

adminRoutes.use("*", adminAuth);

adminRoutes.get("/metrics", (c) => {
  const db = getDb();
  const userCount = (db.prepare("SELECT COUNT(*) as c FROM users WHERE deleted_at IS NULL").get() as { c: number }).c;
  const premiumCount = (db.prepare("SELECT COUNT(*) as c FROM users WHERE is_premium = 1 AND deleted_at IS NULL").get() as {
    c: number;
  }).c;
  const clipCount = (db.prepare("SELECT COUNT(*) as c FROM clips WHERE deleted_at IS NULL").get() as { c: number }).c;
  const cloudClips = (db.prepare("SELECT COUNT(*) as c FROM clips WHERE cloud_key IS NOT NULL AND deleted_at IS NULL").get() as {
    c: number;
  }).c;

  return c.json({
    mau: userCount,
    totalUsers: userCount,
    premiumUsers: premiumCount,
    storage: {
      clipRecords: clipCount,
      cloudAudioFiles: cloudClips,
    },
    crashRate: 0,
    asOf: new Date().toISOString(),
  });
});

adminRoutes.get("/users", (c) => {
  const limit = Math.min(Number(c.req.query("limit") ?? 50), 100);
  const offset = Number(c.req.query("offset") ?? 0);
  const { users, total } = listUsers(limit, offset);
  return c.json({
    users: users.map((u) => ({
      id: u.id,
      email: u.email,
      isPremium: Boolean(u.is_premium),
      createdAt: u.created_at,
    })),
    total,
    limit,
    offset,
  });
});

const premiumSchema = z.object({ isPremium: z.boolean() });

adminRoutes.patch("/users/:id/premium", async (c) => {
  const userId = c.req.param("id");
  const body = premiumSchema.parse(await c.req.json());
  const user = setPremium(userId, body.isPremium);
  if (!user) throw new ApiError("USER_NOT_FOUND", "User not found", 404);
  return c.json({
    id: user.id,
    email: user.email,
    isPremium: Boolean(user.is_premium),
  });
});

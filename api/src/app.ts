import { Hono } from "hono";
import { cors } from "hono/cors";
import { handleError } from "./lib/errors.js";
import { authRoutes } from "./routes/auth.js";
import { syncRoutes } from "./routes/sync.js";
import { audioRoutes } from "./routes/audio.js";
import { adminRoutes } from "./routes/admin.js";

export function createApp() {
  const app = new Hono();

  app.use("*", cors({ origin: "*", allowHeaders: ["Authorization", "Content-Type", "X-Admin-Key"] }));

  app.get("/health", (c) => c.json({ status: "ok", version: "1.0.0" }));

  const v1 = new Hono();

  v1.route("/auth", authRoutes);
  v1.route("/sync", syncRoutes);
  v1.route("/audio", audioRoutes);
  v1.route("/admin", adminRoutes);

  app.route("/v1", v1);

  app.onError((err, c) => handleError(c, err));

  return app;
}

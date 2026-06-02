import type { MiddlewareHandler } from "hono";
import { config } from "../config.js";
import { ApiError } from "../lib/errors.js";

export const adminAuth: MiddlewareHandler = async (c, next) => {
  const key = c.req.header("X-Admin-Key") ?? c.req.header("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!key || key !== config.adminApiKey) {
    throw new ApiError("ADMIN_UNAUTHORIZED", "Invalid admin credentials", 401);
  }
  await next();
};

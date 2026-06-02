import type { MiddlewareHandler } from "hono";
import { ApiError } from "../lib/errors.js";
import { verifyToken } from "../lib/jwt.js";

export type AuthVariables = { userId: string; email: string };

export const bearerAuth: MiddlewareHandler<{ Variables: AuthVariables }> = async (c, next) => {
  const header = c.req.header("Authorization");
  if (!header?.startsWith("Bearer ")) {
    throw new ApiError("UNAUTHORIZED", "Missing or invalid Authorization header", 401);
  }
  const token = header.slice(7);
  const payload = verifyToken(token, "access");
  c.set("userId", payload.sub);
  c.set("email", payload.email);
  await next();
};

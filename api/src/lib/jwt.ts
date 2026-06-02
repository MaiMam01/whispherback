import jwt from "jsonwebtoken";
import { config } from "../config.js";
import type { JwtPayload } from "../types.js";
import { ApiError } from "./errors.js";

export function signAccessToken(userId: string, email: string): string {
  const payload: JwtPayload = { sub: userId, email, type: "access" };
  return jwt.sign(payload, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
}

export function signRefreshToken(userId: string, email: string): string {
  const payload: JwtPayload = { sub: userId, email, type: "refresh" };
  return jwt.sign(payload, config.jwtSecret, { expiresIn: "30d" });
}

export function verifyToken(token: string, expectedType?: JwtPayload["type"]): JwtPayload {
  try {
    const decoded = jwt.verify(token, config.jwtSecret) as JwtPayload;
    if (expectedType && decoded.type !== expectedType) {
      throw new ApiError("INVALID_TOKEN", "Invalid token type", 401);
    }
    return decoded;
  } catch (e) {
    if (e instanceof ApiError) throw e;
    throw new ApiError("INVALID_TOKEN", "Invalid or expired token", 401);
  }
}

import { Hono } from "hono";
import { z } from "zod";
import { bearerAuth, type AuthVariables } from "../middleware/auth.js";
import { signAccessToken, signRefreshToken, verifyToken } from "../lib/jwt.js";
import { ApiError } from "../lib/errors.js";
import {
  createUser,
  findUserByEmail,
  findOrCreateGoogleUser,
  softDeleteUser,
  verifyPassword,
} from "../services/user.js";

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

const googleSchema = z.object({
  idToken: z.string().min(1),
  email: z.string().email().optional(),
});

/** Dev-only: decode a fake Google token as `google:<sub>:<email>` */
function parseGoogleToken(idToken: string, fallbackEmail?: string): { sub: string; email: string } {
  if (idToken.startsWith("google:")) {
    const [, sub, email] = idToken.split(":");
    if (sub && email) return { sub, email };
  }
  if (fallbackEmail) return { sub: `google-${idToken.slice(0, 12)}`, email: fallbackEmail };
  throw new ApiError("INVALID_GOOGLE_TOKEN", "Provide email with idToken in dev, or use google:sub:email format", 400);
}

export const authRoutes = new Hono<{ Variables: AuthVariables }>();

authRoutes.post("/register", async (c) => {
  const body = registerSchema.parse(await c.req.json());
  const user = createUser(body.email, body.password);
  const accessToken = signAccessToken(user.id, user.email);
  const refreshToken = signRefreshToken(user.id, user.email);
  return c.json({
    user: { id: user.id, email: user.email, isPremium: Boolean(user.is_premium) },
    accessToken,
    refreshToken,
    expiresIn: process.env.JWT_EXPIRES_IN ?? "7d",
  }, 201);
});

authRoutes.post("/login", async (c) => {
  const body = loginSchema.parse(await c.req.json());
  const user = findUserByEmail(body.email);
  if (!user || !verifyPassword(user, body.password)) {
    throw new ApiError("INVALID_CREDENTIALS", "Invalid email or password", 401);
  }
  const accessToken = signAccessToken(user.id, user.email);
  const refreshToken = signRefreshToken(user.id, user.email);
  return c.json({
    user: { id: user.id, email: user.email, isPremium: Boolean(user.is_premium) },
    accessToken,
    refreshToken,
  });
});

authRoutes.post("/google", async (c) => {
  const body = googleSchema.parse(await c.req.json());
  const { sub, email } = parseGoogleToken(body.idToken, body.email);
  const user = findOrCreateGoogleUser(email, sub);
  const accessToken = signAccessToken(user.id, user.email);
  const refreshToken = signRefreshToken(user.id, user.email);
  return c.json({
    user: { id: user.id, email: user.email, isPremium: Boolean(user.is_premium) },
    accessToken,
    refreshToken,
  });
});

authRoutes.post("/refresh", async (c) => {
  const body = refreshSchema.parse(await c.req.json());
  const payload = verifyToken(body.refreshToken, "refresh");
  const accessToken = signAccessToken(payload.sub, payload.email);
  return c.json({ accessToken, expiresIn: process.env.JWT_EXPIRES_IN ?? "7d" });
});

authRoutes.delete("/account", bearerAuth, async (c) => {
  const userId = c.get("userId");
  softDeleteUser(userId);
  return c.json({ deleted: true, dataWipeScheduledDays: 30 });
});

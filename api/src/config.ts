import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

function env(key: string, fallback?: string): string {
  const v = process.env[key] ?? fallback;
  if (v === undefined) throw new Error(`Missing env: ${key}`);
  return v;
}

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

export const config = {
  port: Number(process.env.PORT ?? 3000),
  host: process.env.HOST ?? "0.0.0.0",
  jwtSecret: env("JWT_SECRET", "dev-secret-change-in-production"),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? "7d",
  adminApiKey: env("ADMIN_API_KEY", "dev-admin-key"),
  databasePath: resolve(root, process.env.DATABASE_PATH ?? "./data/whisperback.db"),
  uploadDir: resolve(root, process.env.UPLOAD_DIR ?? "./data/uploads"),
  baseUrl: (process.env.BASE_URL ?? "http://localhost:3000/v1").replace(/\/$/, ""),
};

mkdirSync(dirname(config.databasePath), { recursive: true });
mkdirSync(config.uploadDir, { recursive: true });

import Database from "better-sqlite3";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../config.js";

let _db: Database.Database | null = null;

export function getDb(): Database.Database {
  if (_db) return _db;
  _db = new Database(config.databasePath);
  _db.pragma("journal_mode = WAL");
  _db.pragma("foreign_keys = ON");
  const schemaPath = join(dirname(fileURLToPath(import.meta.url)), "schema.sql");
  _db.exec(readFileSync(schemaPath, "utf-8"));
  return _db;
}

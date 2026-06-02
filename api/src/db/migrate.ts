import Database from "better-sqlite3";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../config.js";

const schemaPath = join(dirname(fileURLToPath(import.meta.url)), "schema.sql");
const sql = readFileSync(schemaPath, "utf-8");

const db = new Database(config.databasePath);
db.exec(sql);
console.log(`Migrated database at ${config.databasePath}`);

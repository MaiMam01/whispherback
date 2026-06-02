import { serve } from "@hono/node-server";
import { config } from "./config.js";
import { createApp } from "./app.js";
import { getDb } from "./db/index.js";

getDb();

const app = createApp();

console.log(`WhisperBack API listening on http://${config.host}:${config.port}/v1`);
console.log(`Health: http://localhost:${config.port}/health`);

serve({ fetch: app.fetch, hostname: config.host, port: config.port });

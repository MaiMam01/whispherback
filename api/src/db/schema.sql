-- WhisperBack API schema (mirrors mobile sync entities)

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  google_sub TEXT UNIQUE,
  is_premium INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  last_sync_at TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS playlists (
  id TEXT NOT NULL,
  user_id TEXT NOT NULL REFERENCES users(id),
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS clips (
  id TEXT NOT NULL,
  user_id TEXT NOT NULL REFERENCES users(id),
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  cloud_key TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS schedules (
  id TEXT NOT NULL,
  user_id TEXT NOT NULL REFERENCES users(id),
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  PRIMARY KEY (id, user_id)
);

CREATE TABLE IF NOT EXISTS sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  direction TEXT NOT NULL,
  entity_counts TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_playlists_user_updated ON playlists(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_clips_user_updated ON clips(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_schedules_user_updated ON schedules(user_id, updated_at);

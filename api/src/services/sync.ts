import { getDb } from "../db/index.js";
import type { EntityType, PushPayload, SyncEntity } from "../types.js";

const TABLES: Record<EntityType, string> = {
  playlists: "playlists",
  clips: "clips",
  schedules: "schedules",
};

function parsePayload(row: { payload: string; updated_at: string; id: string }): SyncEntity {
  const data = JSON.parse(row.payload) as Record<string, unknown>;
  return { ...data, id: row.id, updatedAt: row.updated_at };
}

export function pullChanges(
  userId: string,
  since?: string,
): { playlists: SyncEntity[]; clips: SyncEntity[]; schedules: SyncEntity[]; serverTime: string } {
  const serverTime = new Date().toISOString();
  const result = { playlists: [] as SyncEntity[], clips: [] as SyncEntity[], schedules: [] as SyncEntity[], serverTime };

  for (const [key, table] of Object.entries(TABLES) as [EntityType, string][]) {
    const rows = since
      ? (getDb()
          .prepare(
            `SELECT id, payload, updated_at FROM ${table}
             WHERE user_id = ? AND updated_at > ? AND deleted_at IS NULL
             ORDER BY updated_at ASC`,
          )
          .all(userId, since) as { id: string; payload: string; updated_at: string }[])
      : (getDb()
          .prepare(
            `SELECT id, payload, updated_at FROM ${table}
             WHERE user_id = ? AND deleted_at IS NULL
             ORDER BY updated_at ASC`,
          )
          .all(userId) as { id: string; payload: string; updated_at: string }[]);

    result[key] = rows.map(parsePayload);
  }

  return result;
}

function entityUpdatedAt(entity: SyncEntity): string {
  const ts = entity.updatedAt ?? entity.updated_at;
  if (typeof ts !== "string") return new Date().toISOString();
  return ts;
}

function applyEntity(userId: string, table: string, entity: SyncEntity, pushTimestamp: string): void {
  const id = entity.id;
  if (!id) return;

  const updatedAt = entityUpdatedAt(entity);
  const existing = getDb()
    .prepare(`SELECT updated_at, deleted_at FROM ${table} WHERE id = ? AND user_id = ?`)
    .get(id, userId) as { updated_at: string; deleted_at: string | null } | undefined;

  if (existing?.deleted_at) return;

  if (existing && existing.updated_at > updatedAt) {
    return;
  }

  const payload = JSON.stringify({ ...entity, id: undefined, updatedAt: undefined, updated_at: undefined });
  if (existing) {
    getDb()
      .prepare(`UPDATE ${table} SET payload = ?, updated_at = ?, deleted_at = NULL WHERE id = ? AND user_id = ?`)
      .run(payload, updatedAt, id, userId);
  } else {
    getDb()
      .prepare(`INSERT INTO ${table} (id, user_id, payload, updated_at) VALUES (?, ?, ?, ?)`)
      .run(id, userId, payload, updatedAt);
  }
}

function applyDeletes(userId: string, table: string, ids: string[], pushTimestamp: string): void {
  for (const id of ids) {
    const existing = getDb()
      .prepare(`SELECT updated_at FROM ${table} WHERE id = ? AND user_id = ?`)
      .get(id, userId) as { updated_at: string } | undefined;
    if (existing && existing.updated_at > pushTimestamp) continue;
    if (existing) {
      getDb()
        .prepare(`UPDATE ${table} SET deleted_at = ?, updated_at = ? WHERE id = ? AND user_id = ?`)
        .run(pushTimestamp, pushTimestamp, id, userId);
    } else {
      getDb()
        .prepare(`INSERT INTO ${table} (id, user_id, payload, updated_at, deleted_at) VALUES (?, ?, '{}', ?, ?)`)
        .run(id, userId, pushTimestamp, pushTimestamp);
    }
  }
}

export function pushChanges(userId: string, payload: PushPayload): { accepted: boolean; serverTime: string } {
  const serverTime = new Date().toISOString();
  const pushTs = payload.timestamp || serverTime;

  for (const entity of payload.playlists) applyEntity(userId, "playlists", entity, pushTs);
  for (const entity of payload.clips) applyEntity(userId, "clips", entity, pushTs);
  for (const entity of payload.schedules) applyEntity(userId, "schedules", entity, pushTs);

  applyDeletes(userId, "playlists", payload.deletedIds.playlists ?? [], pushTs);
  applyDeletes(userId, "clips", payload.deletedIds.clips ?? [], pushTs);
  applyDeletes(userId, "schedules", payload.deletedIds.schedules ?? [], pushTs);

  getDb()
    .prepare(
      `INSERT INTO sync_log (user_id, device_id, direction, entity_counts, created_at)
       VALUES (?, ?, 'push', ?, ?)`,
    )
    .run(
      userId,
      payload.deviceId,
      JSON.stringify({
        playlists: payload.playlists.length,
        clips: payload.clips.length,
        schedules: payload.schedules.length,
      }),
      serverTime,
    );

  return { accepted: true, serverTime };
}

export function getSyncStatus(userId: string): {
  lastSyncAt: string | null;
  conflictCount: number;
} {
  const row = getDb()
    .prepare("SELECT MAX(last_sync_at) as last_sync FROM devices WHERE user_id = ?")
    .get(userId) as { last_sync: string | null };
  return { lastSyncAt: row.last_sync, conflictCount: 0 };
}

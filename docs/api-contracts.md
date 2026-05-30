# API Contracts — Phase 2 (AWS Backend)

Base URL: `https://api.whisperback.app/v1` (staging: `https://staging-api.whisperback.app/v1`)

All endpoints require `Authorization: Bearer <cognito_id_token>` unless noted.

## Authentication

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Email + password registration |
| POST | `/auth/login` | Email + password login |
| POST | `/auth/google` | Google OAuth token exchange |
| POST | `/auth/refresh` | Refresh token |
| DELETE | `/auth/account` | Delete account (30-day data wipe) |

## Sync

| Method | Path | Description |
|--------|------|-------------|
| GET | `/sync/pull?since=<timestamp>` | Pull changes since last sync |
| POST | `/sync/push` | Push local changes batch |
| GET | `/sync/status` | Last sync timestamp, conflict count |

### Push payload

```json
{
  "deviceId": "uuid",
  "timestamp": "2026-05-02T12:00:00Z",
  "playlists": [],
  "clips": [],
  "schedules": [],
  "deletedIds": { "playlists": [], "clips": [], "schedules": [] }
}
```

**Conflict policy:** Last write wins (device with most recent `timestamp` per entity).

## Audio files (Premium)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/audio/upload-url` | Get S3 pre-signed upload URL |
| POST | `/audio/confirm` | Confirm upload complete |
| GET | `/audio/download-url/:clipId` | Get 1-hour expiring playback URL |
| DELETE | `/audio/:clipId` | Remove cloud copy |

## Admin (separate auth)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/admin/metrics` | MAU, storage, crash rate |
| GET | `/admin/users` | Paginated user list |
| PATCH | `/admin/users/:id/premium` | Toggle Premium flag |

## Error format

```json
{
  "error": {
    "code": "SCHEDULE_CONFLICT",
    "message": "Human-readable message"
  }
}
```

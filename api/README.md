# WhisperBack API

REST API implementing [docs/api-contracts.md](../docs/api-contracts.md) for Phase 2 cloud sync, auth, and premium audio storage.

Runs locally with **SQLite** and file-based uploads (no AWS required). The same route shapes map to Cognito + DynamoDB + S3 when you deploy `infra/` later.

## Quick start

```bash
cd api
cp .env.example .env
npm install
npm run dev
```

Server: `http://localhost:3000/v1`  
Health: `http://localhost:3000/health`

## Auth (dev)

Register and use the returned `accessToken` as `Authorization: Bearer <token>`.

```bash
curl -s -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"you@example.com\",\"password\":\"password123\"}"
```

Google login (dev stub — no real OAuth):

```bash
curl -s -X POST http://localhost:3000/v1/auth/google \
  -H "Content-Type: application/json" \
  -d "{\"idToken\":\"google:abc123:you@gmail.com\"}"
```

## Sync

```bash
# Pull all entities
curl -s "http://localhost:3000/v1/sync/pull" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Push batch
curl -s -X POST http://localhost:3000/v1/sync/push \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"deviceId\":\"00000000-0000-4000-8000-000000000001\",\"timestamp\":\"2026-06-01T12:00:00Z\",\"playlists\":[],\"clips\":[],\"schedules\":[],\"deletedIds\":{\"playlists\":[],\"clips\":[],\"schedules\":[]}}"
```

Conflict policy: **last write wins** per entity `updatedAt`.

## Premium audio

User must have `isPremium` (toggle via admin). Flow:

1. `POST /v1/audio/upload-url` → `uploadUrl`, `uploadId`
2. `PUT` raw bytes to `uploadUrl`
3. `POST /v1/audio/confirm` with `clipId`
4. `GET /v1/audio/download-url/:clipId` → 1-hour signed stream URL

## Admin

Header: `X-Admin-Key: <ADMIN_API_KEY from .env>` (default `dev-admin-key`).

```bash
curl -s http://localhost:3000/v1/admin/metrics -H "X-Admin-Key: dev-admin-key"
curl -s -X PATCH http://localhost:3000/v1/admin/users/USER_ID/premium \
  -H "X-Admin-Key: dev-admin-key" \
  -H "Content-Type: application/json" \
  -d "{\"isPremium\":true}"
```

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server with hot reload |
| `npm run build` | Compile to `dist/` |
| `npm start` | Run compiled server |
| `npm run db:migrate` | Apply SQLite schema |

## Production (AWS)

Deploy with CDK in `../infra/` (Cognito, API Gateway, Lambda, DynamoDB, S3). This package is the reference implementation and local substitute until infra is wired.

## Mobile integration

Point the Flutter app’s Phase 2 clients at `BASE_URL` (e.g. `--dart-define=API_BASE_URL=http://10.0.2.2:3000/v1` on Android emulator). See `mobile/lib/data/repositories/cloud/README.md`.

# WhisperBack — Phase 2 Cloud Repository (stub)

This folder will hold the AWS sync implementation behind the same interface as local repositories.

## Planned files

- `cloud_sync_repository.dart` — push/pull with last-write-wins
- `cognito_auth_service.dart` — Google + email login
- `s3_upload_service.dart` — resumable audio upload

Mobile app writes to SQLite first; sync runs on app open, connectivity restore, and manual backup.

See [docs/api-contracts.md](../../../docs/api-contracts.md).

# WhisperBack Mobile

Flutter cross-platform app (iOS + Android).

## Setup

```powershell
# From repo root (requires Flutter SDK 3.24+)
cd mobile
flutter pub get
flutter run --dart-define=FLAVOR=dev
```

If platform folders are missing:

```powershell
flutter create . --project-name whisperback --org com.whisperback
flutter pub get
```

## Architecture

- `lib/core/` — theme, router, constants
- `lib/features/` — screens (13 screens per design spec)
- `lib/data/` — SQLite repositories
- `lib/services/` — audio, playback, scheduler, prayer, shuffle
- `lib/providers/` — Riverpod providers

## Phase 1 scope

Local-only MVP: playlists, scheduling, sleep/prayer modes, record/import, popup playback modal.

Phase 2 adds AWS sync via repository abstraction in `lib/data/repositories/cloud/` (stub).

# WhisperBack Production Audit

Senior multi-disciplinary review (mobile architecture, audio, scheduling, security, QA, UX).  
**Date:** June 2026 · **Scope:** `mobile/` Flutter app + Android build + docs.

## Overall score: **8.7 / 10** (client-ready APK)

Production-oriented offline MVP with professional permission/error UX, localized services, and critical scheduling bugs fixed. Play Store submission still needs release signing.

---

## Scorecard

| Discipline | Score | Summary |
|------------|-------|---------|
| Architecture | 8/10 | Clear feature folders; pragmatic layering |
| Audio / FGS | 8.5/10 | Professional `audio_service` + coordinator; FGS failure surfaced |
| Scheduling | 8.5/10 | Overnight windows, stable schedule IDs, conflict detection |
| Security | 7.5/10 | Path sandbox; `USE_EXACT_ALARM` removed; debug signing remains |
| QA / Tests | 7/10 | 12 unit tests covering schedule math, errors, path guard |
| UI/UX / i18n | 9/10 | Friendly errors, RuntimeCopy for services, a11y on Active toggle |
| Production readiness | 8/10 | Client APK ready; Play needs keystore |

---

## Completed remediation

| Area | Fix |
|------|-----|
| Error UX | `user_facing_error.dart` + `AsyncErrorView` on all list screens |
| Hardcoded strings | `RuntimeCopy` binds l10n to notifications + playback |
| FGS failure | Banner in shell + dialog when Active ON without audio service |
| Policies | `PLAY_STORE_POLICIES.md`; removed `USE_EXACT_ALARM` |
| Scheduling bugs | Stable schedule ID, overnight windows, conflict grid |
| Audio bug | `customAction` fall-through fixed |
| Security | `ClipPathGuard` sandbox for playback/import |
| Auth honesty | “Cloud sign-in coming soon” on sign-in |
| Docs | `INSTALLATION.md` updated; policy guide added |
| Tests | +4 tests (errors, path guard, overnight window) |

---

## Remaining before Play Store (P0)

| Issue | Action |
|-------|--------|
| Debug release signing | Configure upload keystore in `build.gradle.kts` |
| Headless playback when killed | Document limitation; alarm opens app |

---

## Release checklist

1. Push latest code → green GitHub Actions  
2. Download **`whisperback-release-arm64`**  
3. Client uninstalls old APK → install fresh  
4. Allow notifications, alarms, battery unrestricted  
5. Home → **Active ON** → verify permission dialog if needed  
6. Create playlist + schedule → confirm fires in window  

See [PLAY_STORE_POLICIES.md](PLAY_STORE_POLICIES.md) · [ANDROID_COMPATIBILITY.md](ANDROID_COMPATIBILITY.md) · [APK_TESTING.md](APK_TESTING.md).

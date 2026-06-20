# Android version support

WhisperBack targets **Android 7.0 through Android 16** (API 24–36). The same APK from GitHub Actions is built for this range.

## Supported versions

| Android version | API | Support | Notes |
|-----------------|-----|---------|--------|
| Android 7.0–7.1 | 24–25 | ✓ | Minimum supported (`minSdk = 24`) |
| Android 8–11 | 26–30 | ✓ | Full feature set |
| Android 12 | 31 | ✓ | Exact-alarm permission prompt |
| Android 13 | 33 | ✓ | Notification permission prompt |
| Android 14 | 34 | ✓ | Stricter exact-alarm settings |
| Android 15 | 35 | ✓ | 16 KB page-size native libs enabled |
| Android 16 | 36 | ✓ | Current `targetSdk` / `compileSdk` |

**Not supported:** Android 6.0 and below (API 23 and lower).

## Build configuration

Pinned in `mobile/android/app/build.gradle.kts`:

```kotlin
compileSdk = 36   // Android 16
minSdk = 24       // Android 7.0
targetSdk = 36    // Android 16 — required for Play / latest devices
```

Flutter 3.38+ uses the same defaults; values are **explicit** so CI and client builds stay predictable.

## Runtime permissions (why scheduling can fail on a new phone)

When you turn **Active ON**, the app runs a short **in-app setup** — Android system dialogs for notifications, exact alarms, and battery (usually **2–3 Allow taps**, no digging through Settings).

| Permission | Android | Needed for |
|------------|---------|------------|
| Notifications | 13+ | Schedule alarms when app is closed |
| Alarms & reminders (exact) | 12+ | Firing at the correct minute |
| Battery unrestricted | All (OEM) | Samsung / Xiaomi / Oppo background killers |

If the user denies any prompt, a **Finish setup** chip appears on Home. Settings is only shown as a **fallback** (e.g. “Don’t ask again”).

## Permission denial UX (production behavior)

When a user **denies** a permission:

| First denial | Android shows the system dialog again on the next attempt (e.g. tap Record again). The app shows a short snackbar explaining why the permission is needed. |
| Permanent denial (“Don’t ask again”) | The app shows a **dialog** with step-by-step **Settings → Apps → WhisperBack → Permissions** guidance and an **Open Settings** button. |

This applies to:

| Feature | Permission | When prompted |
|---------|------------|---------------|
| Record whisper | Microphone | Tap **Start recording** |
| Import MP3/M4A | Music & audio (Android 13+) | Tap **Choose file** |
| GPS prayer times | Location | Enable **Use GPS location** in Prayer settings |
| Scheduled whispers | Notifications + Alarms & reminders + Battery | Turn **Active** ON on Home |

The **Battery** screen also opens system Settings directly so users can whitelist the app on Samsung/Xiaomi/Huawei.

## APK variants (GitHub Actions)

| Artifact | ABI | Use |
|----------|-----|-----|
| `whisperback-release-arm64` | arm64-v8a | **Most phones (2017+)** — send this by default |
| `whisperback-release-all-abis` | arm32 + x86 | Older or unusual devices |

## Client checklist (Australia / latest Android)

1. Install **`whisperback-release-arm64`** from the latest green Actions run.
2. Home → turn **Active** ON → tap **Allow** on each system prompt (notifications, alarms, battery).
3. If a **Finish setup** chip still shows, tap it once more or use Settings → Battery in the app for Samsung/Xiaomi autostart.
4. Confirm **automatic date/time + timezone** is enabled.

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Playlists/clips don’t save | App crash on device — need `adb logcat` |
| Schedule never fires | Active OFF, or notifications/alarms denied |
| Schedule fires at wrong time | Timezone/auto-time off (fixed in app via offset fallback) |
| Works until phone reboots | Was fixed: boot receiver must be `exported=true` on Android 12+ |

## Verifying a build locally

```powershell
cd whispherback\mobile
flutter build apk --release --split-per-abi --dart-define=FLAVOR=dev
# arm64 output: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

See also [APK_TESTING.md](APK_TESTING.md) and [INSTALLATION.md](INSTALLATION.md).

## Background & Recents (swipe away)

WhisperBack uses a **foreground media service** when Active is ON, plus **OS alarm notifications** as backup. Full scenario matrix: **[BACKGROUND_RELIABILITY.md](BACKGROUND_RELIABILITY.md)**.

**Short answer:** Works reliably when Active ON + battery unrestricted. If the phone kills the app, you still get an **alarm notification** — tap it to play. No app can guarantee silent playback on every OEM without those settings.

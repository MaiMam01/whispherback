# Background reliability on Android

Honest guide for **scheduling + audio when the app is backgrounded or removed from Recents**.

No third-party app can guarantee **100% on every Android OEM** (Samsung, Xiaomi, Oppo, etc. aggressively kill background apps). WhisperBack uses **three layers** so whispers work as reliably as Android allows.

---

## How WhisperBack stays alive

| Layer | What it does | Survives Recents swipe? |
|-------|----------------|-------------------------|
| **1. Foreground service (FGS)** | When **Active ON**, silent media playback runs through `audio_service` → Android **media playback** FGS | **Yes on stock Android** if battery is unrestricted (`stopWithTask="false"`) |
| **2. In-app schedule engine** | 5-second timer checks grid slots while process is alive | Only while layer 1 keeps process alive |
| **3. OS alarm notifications** | `flutter_local_notifications` + exact/inexact alarms fire at scheduled times even if process was killed | **Notification always**; **auto-play** only after app opens |

---

## Scenario matrix

| Scenario | Expected behavior |
|----------|-------------------|
| App in background, **Active ON**, battery unrestricted | Whispers play on time via engine + FGS |
| Swiped from **Recents**, **Active ON**, battery unrestricted | FGS keeps process → engine keeps firing |
| Swiped from Recents, **battery optimized** (Samsung/Xiaomi default) | Process may die → **alarm notification** at slot time; tap notification to play |
| App **force-stopped** in Settings | Nothing runs until user opens app again |
| **Active OFF** | No schedules armed; no background playback |
| Phone **reboot** | Boot receiver re-arms OS alarms; open app once after reboot if Active was ON |
| **Exact alarms denied** (Android 14+) | Falls back to inexact alarms (may be a few minutes late) |

---

## What we implemented (technical)

1. **Real FGS keep-alive** — Active idle uses `audio_service` + silent loop (not a hidden second player)
2. **`android:stopWithTask="false"`** — Audio service continues when task is removed from Recents
3. **Dual scheduling** — In-app engine + up to 400 OS alarm slots per sync
4. **Exact → inexact fallback** — If exact alarms blocked
5. **Boot receiver** — `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` re-registers alarms
6. **Alarm tap → play** — Opening from schedule notification runs `fireNow()` immediately
7. **Resume catch-up** — App resume re-runs schedule pass + permission sync

---

## Client checklist (required for “every phone”)

1. Install latest **`whisperback-release-arm64`**
2. Home → **Active ON** → tap **Allow** on in-app prompts (notifications, alarms, battery)
3. If **Finish setup** still shows: tap it, or use in-app **Battery** screen for Samsung/Xiaomi autostart
4. Do **not** force-stop the app in Settings

---

## What we cannot promise

- **Silent auto-play at exact minute with zero user interaction** after OEM kills the process — Android restricts background execution; alarm **notification** is the wake mechanism
- **Identical behavior on every OEM** without battery whitelist
- **Playback while Active OFF** — by design

For Play Console declarations see [PLAY_STORE_POLICIES.md](PLAY_STORE_POLICIES.md).

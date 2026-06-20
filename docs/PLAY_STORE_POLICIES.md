# Play Store & Android policy guide

WhisperBack is an **offline audio scheduling app**. These choices align with Google Play and Android 12–16 best practices.

## Permissions (declared in `AndroidManifest.xml`)

| Permission | Why | Play Console declaration |
|------------|-----|--------------------------|
| `RECORD_AUDIO` | Record whispers | Core feature — microphone |
| `READ_MEDIA_AUDIO` | Import MP3/M4A (Android 13+) | Photos/videos/audio — audio only |
| `READ_EXTERNAL_STORAGE` (maxSdk 32) | Legacy import | Same |
| `ACCESS_FINE/COARSE_LOCATION` | Optional GPS prayer times | Location — approximate/precise when GPS ON |
| `POST_NOTIFICATIONS` | Schedule alarms + status | Notifications |
| `SCHEDULE_EXACT_ALARM` | Fire at exact minute | Alarms & reminders — user grants at runtime |
| `RECEIVE_BOOT_COMPLETED` | Re-arm schedules after reboot | Standard for schedulers |
| `FOREGROUND_SERVICE` + `MEDIA_PLAYBACK` | Background whispers + lock screen | Foreground service — media playback |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | OEM battery killers | Sensitive — justify in Console + in-app battery screen |
| `WAKE_LOCK` | Brief wake for alarm delivery | Normal for alarms |

### Removed on purpose

- **`USE_EXACT_ALARM`** — reserved for alarm-clock apps. WhisperBack uses **`SCHEDULE_EXACT_ALARM`** with runtime prompt instead (Play-policy friendly).

## In-app policy UX

1. **First deny** → snackbar explaining why + optional Open Settings  
2. **Permanent deny** → dialog with `Settings → Apps → WhisperBack → Permissions` steps  
3. **Active ON** → combined dialog if notifications, alarms, or battery still missing  
4. **Auth screens** → “Cloud sign-in coming soon; app works fully offline today”  
5. **Errors** → friendly localized messages, never raw exception text  

## Release checklist

1. **Upload keystore** — replace debug signing in `build.gradle.kts`  
2. **Data safety form** — no data collected in Phase 1 (on-device SQLite only)  
3. **Permission declarations** — match table above in Play Console  
4. **Battery exemption** — link to in-app Battery screen in review notes  
5. **Exact alarms** — explain scheduled whisper playback in review notes  

## Client APK (outside Play Store)

Same APK from GitHub Actions is fine for direct install. Users must:

- Allow notifications + alarms when prompted  
- Battery → Unrestricted on Samsung/Xiaomi/Oppo  
- Turn **Active ON** on Home  

See [ANDROID_COMPATIBILITY.md](ANDROID_COMPATIBILITY.md) and [PRODUCTION_AUDIT.md](PRODUCTION_AUDIT.md).

# WhisperBack Mobile — Complete Walkthrough

**Audience:** Developers new to mobile (and possibly new to Flutter) who will build and maintain the WhisperBack app.  
**Last updated:** June 2026  
**Source of truth:** `design/ui-preview.html` (client-approved UI), `design/screen-specs.md`, and code under `mobile/`.

---

## Is this app starting from scratch?

**No.** The Flutter app under `mobile/` is already built: screens, navigation, SQLite, playback logic, scheduling, and UI aligned to `design/ui-preview.html`. You extend and fix it—see [PROJECT_AUDIT.md](PROJECT_AUDIT.md) for completion status (~45% MVP maturity).

---

## Table of contents

1. [What you are building](#1-what-you-are-building)
2. [Repository map](#2-repository-map)
3. [Do you need Flutter, Gradle, or something else?](#3-do-you-need-flutter-gradle-or-something-else)
4. [Install toolchain (Windows focus)](#4-install-toolchain-windows-focus)
5. [First run on your machine](#5-first-run-on-your-machine)
6. [Approved design → Flutter implementation](#6-approved-design--flutter-implementation)
7. [All 13 screens and routes](#7-all-13-screens-and-routes)
8. [How the Flutter app is organized](#8-how-the-flutter-app-is-organized)
9. [Core concepts for mobile beginners](#9-core-concepts-for-mobile-beginners)
10. [Data layer: SQLite and repositories](#10-data-layer-sqlite-and-repositories)
11. [Playback: the heart of the product](#11-playback-the-heart-of-the-product)
12. [Scheduling, sleep, and prayer](#12-scheduling-sleep-and-prayer)
13. [State management with Riverpod](#13-state-management-with-riverpod)
14. [Navigation with go_router](#14-navigation-with-go_router)
15. [Theming and matching `ui-preview.html`](#15-theming-and-matching-ui-previewhtml)
16. [Day-to-day development workflow](#16-day-to-day-development-workflow)
17. [Testing and QA](#17-testing-and-qa)
18. [Phase 1 vs Phase 2](#18-phase-1-vs-phase-2)
19. [Known gaps (audit summary)](#19-known-gaps-audit-summary)
20. [Learning path (suggested order)](#20-learning-path-suggested-order)
21. [Quick reference commands](#21-quick-reference-commands)

---

## 1. What you are building

**WhisperBack** is a cross-platform **iOS + Android** app that plays **personal audio clips** on a **schedule**—like gentle “whispers” throughout the day. Users:

- Turn the app **Active / Inactive** (master switch on Home).
- Create **playlists** of clips (recorded or imported).
- Set **interval schedules** (e.g. every 30 minutes between 9:00 and 17:00).
- Use **Sleep mode** and **Prayer mode** to pause playback during silence windows.
- Control playback from a **bottom-sheet modal** (not a full-screen music player).

**Phase 1 (current):** Everything runs **offline** on the device. SQLite stores data; no login required for core features.  
**Phase 2 (later):** AWS sync, Cognito auth, cloud audio—see `docs/api-contracts.md`.

The **approved visual design** lives in the browser—open it anytime:

```text
whispherback/design/ui-preview.html
```

Double-click the file or open it in Chrome/Edge. Use the screen picker on the left to walk through Sign In, Home, Playlists, etc., and toggle **light/dark** theme.

---

## 2. Repository map

```text
whispherback/
├── mobile/                 ← YOU WORK HERE (Flutter app)
│   ├── lib/
│   │   ├── main.dart       ← App entry
│   │   ├── app.dart        ← MaterialApp + theme + starts scheduler
│   │   ├── core/           ← Theme, router, shared widgets
│   │   ├── features/       ← One folder per screen/flow
│   │   ├── data/           ← SQLite + repositories
│   │   ├── domain/         ← Entities + playback enums
│   │   ├── services/       ← Audio, scheduler, prayer, shuffle
│   │   └── providers/      ← Riverpod wiring
│   ├── test/               ← Unit tests
│   ├── integration_test/   ← Device/integration tests
│   └── pubspec.yaml        ← Dependencies (like package.json)
├── design/
│   ├── ui-preview.html     ← Client-approved UI mockup
│   ├── screen-specs.md     ← S01–S13 specifications
│   ├── tokens.json         ← Colors, spacing, fonts for Flutter
│   └── README.md           ← Sign-off checklist
├── docs/
│   ├── MOBILE_WALKTHROUGH.md   ← This file
│   ├── PROJECT_AUDIT.md        ← Engineering status & gaps
│   ├── playback-states.md      ← Playback state machine
│   ├── api-contracts.md        ← Phase 2 backend API
│   └── qa-checklist.md         ← Release testing
├── documents/              ← Client questionnaires (HTML)
├── scripts/
│   └── setup_mobile.ps1    ← Windows helper: create android/, pub get, test
├── admin/                  ← Phase 2 Next.js admin
└── infra/                  ← Phase 2 AWS CDK
```

**Important:** The product code is **`mobile/`**. You do not need Node.js or AWS tools until Phase 2 admin/infra work.

---

## 3. Do you need Flutter, Gradle, or something else?

| Tool | Required for WhisperBack? | What it does |
|------|---------------------------|--------------|
| **Flutter SDK** | **Yes — required** | Cross-platform UI framework; includes **Dart** language |
| **Dart** | Bundled with Flutter | Language all `mobile/lib/**/*.dart` is written in |
| **Android Studio** | **Yes** (for Android builds/emulator) | Android SDK, emulator, device drivers; Gradle is installed **inside** the Android project Flutter generates |
| **Gradle** | **No separate install** | Build tool for Android; Flutter creates `android/` with Gradle wrapper when you run `flutter create` |
| **Xcode** | Only on **macOS** for iPhone builds | Not available on Windows for real device/simulator iOS builds |
| **CocoaPods** | iOS only (Mac) | Dependency manager for iOS native plugins; usually `pod install` via Flutter |
| **VS Code + Flutter extension** | Optional but popular | Lighter editor; Android Studio also works |
| **Node.js** | **No** for mobile-only | Used for `admin/` and `infra/` later |
| **React Native / Cordova** | **No** | This project is **Flutter-only** |

**Summary:** Install **Flutter** + **Android Studio**. You do **not** install Gradle or CocoaPods manually unless troubleshooting iOS on a Mac.

**Platform reality on Windows:**

- You can develop and run **Android** emulators and devices.
- **iOS** builds require a Mac with Xcode (or CI on macOS). Plan accordingly for client demos.

---

> **New machine?** Use the step-by-step guide: [INSTALLATION.md](INSTALLATION.md) (Windows, macOS, Linux, checklist, troubleshooting).

## 4. Install toolchain (Windows focus)

### 4.1 Flutter SDK

1. Download the **stable** installer: [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)  
   (Avoid fragile `git clone` if your network drops mid-download—the project audit noted clone failures.)
2. Add Flutter to your **PATH** (installer usually does this).
3. Verify:

```powershell
flutter doctor -v
```

Fix everything `flutter doctor` marks with ❌ before continuing. Typical fixes:

- **Android toolchain** → install Android Studio, accept licenses: `flutter doctor --android-licenses`
- **Chrome** → optional; useful for web debug, not required for phone app
- **Visual Studio** → only if you target Windows desktop (not required for Android/iOS mobile)

**Version:** Project targets **Flutter 3.24+** / Dart 3.5+ (`mobile/pubspec.yaml`: `sdk: '>=3.5.0 <4.0.0'`).

### 4.2 Android Studio

1. Install [Android Studio](https://developer.android.com/studio).
2. Open **SDK Manager** → install a recent **Android SDK Platform** (e.g. API 34).
3. Open **Device Manager** → create a **Virtual Device** (Pixel-class phone).
4. Enable **USB debugging** on a physical device if you test on hardware.

### 4.3 Editor

- **VS Code:** Install extensions “Flutter” and “Dart”.
- **Android Studio:** Enable Flutter plugin.

### 4.4 Optional: repo setup script

From repo root:

```powershell
.\scripts\setup_mobile.ps1
```

This script (see `scripts/setup_mobile.ps1`):

- Expects Flutter at `%LOCALAPPDATA%\flutter-sdk\bin\flutter.bat` **or** Flutter on PATH
- Runs `flutter create .` in `mobile/` if `android/` is missing
- Runs `flutter pub get`, `flutter analyze`, `flutter test`

---

## 5. First run on your machine

### Step 1 — Generate platform folders (if missing)

The repo may not include `android/` and `ios/` in git (they are generated). From `mobile/`:

```powershell
cd D:\whisperback\whispherback\mobile
flutter create . --project-name whisperback --org com.whisperback
flutter pub get
```

### Step 2 — Start emulator or plug in phone

```powershell
flutter devices
```

### Step 3 — Run the app

```powershell
flutter run --dart-define=FLAVOR=dev
```

**Hot reload:** While running, press `r` in the terminal to reload UI after code changes, `R` for full restart.

**What happens on first launch:**

1. `main.dart` → `ProviderScope` → `WhisperBackApp` (`app.dart`)
2. Route `/` → `SplashScreen` (~1.5s)
3. `SeedService` may insert demo data if DB is empty
4. Navigate to `/home`

---

## 6. Approved design → Flutter implementation

| Design asset | Purpose | Flutter counterpart |
|--------------|---------|---------------------|
| `design/ui-preview.html` | Pixel-level reference, animations, copy | Match visually in `features/*` + `core/widgets/*` |
| `design/tokens.json` | Colors, spacing, radii, fonts | `lib/core/theme/app_colors.dart`, `app_theme.dart`, `app_radii.dart` |
| `design/screen-specs.md` | Behavior per screen (S01–S13) | `lib/features/*` + `app_router.dart` routes |
| `design/README.md` | Client sign-off checklist | Track S02, S04, S08, S13 before “done” |

**Design language (v3 preview):**

- **Fonts:** Fraunces (display/titles), DM Sans (body)—via `google_fonts` in Flutter
- **Look:** Dark-first navy gradient (`#020611` → `#061331`), glass cards, soft white accents
- **Nav:** Floating glass bottom bar (and side nav on wide layouts via `adaptive_shell_nav.dart`)
- **Home:** Large central Active/Inactive toggle—**no shuffle on home** (spec rule)
- **Sleep shortcut:** Must show **“Zzz”** text on home, not only a moon icon

When implementing a screen:

1. Open that screen in `ui-preview.html`.
2. Read the matching section in `screen-specs.md`.
3. Edit the Dart file under `lib/features/...`.
4. Reuse widgets from `lib/core/widgets/` (`WhisperCard`, `GlassNavBar`, `ActiveToggle`, etc.).

---

## 7. All 13 screens and routes

| ID | Screen | Route | Flutter file |
|----|--------|-------|----------------|
| S01 | Splash | `/` | `features/splash/splash_screen.dart` |
| — | Sign In | `/sign-in` | `features/auth/sign_in_screen.dart` |
| — | Sign Up | `/sign-up` | `features/auth/sign_up_screen.dart` |
| S02 | Home ★ | `/home` | `features/home/home_screen.dart` |
| S03 | Playlists | `/playlists` | `features/playlists/playlists_screen.dart` |
| S04 | Playlist detail ★ | `/playlists/:id` | `features/playlists/playlist_detail_screen.dart` |
| — | New playlist | `/playlists/new` | `features/playlists/new_playlist_screen.dart` |
| S05 | Clip library | `/clips` | `features/clips/clips_screen.dart` |
| S06 | Record | `/clips/record` | `features/clips/record_screen.dart` |
| S07 | Import | `/clips/import` | `features/clips/import_screen.dart` |
| S08 | Schedule builder ★ | `/schedule/build/:playlistId` | `features/schedule/schedule_builder_screen.dart` |
| S09 | Schedules overview | `/schedule` | `features/schedule/scheduled_overview_screen.dart` |
| S10 | Sleep mode | `/sleep` | `features/sleep/sleep_mode_screen.dart` |
| S11 | Prayer settings | `/prayer` | `features/prayer/prayer_settings_screen.dart` |
| — | Battery guide | `/battery` | `features/device/battery_settings_screen.dart` |
| S12 | Settings | `/settings` | `features/settings/settings_screen.dart` |
| S13 | Playback modal ★ | Overlay in shell | `features/playback/playback_modal.dart` + `core/widgets/main_shell.dart` |

★ = **Client sign-off required** before pixel-perfect polish (`design/README.md`).

Routes are declared in `lib/core/router/app_router.dart`. Most main tabs sit inside a `ShellRoute` that wraps content with `MainShell` (nav bar + playback modal).

---

## 8. How the Flutter app is organized

Think in **layers** (inside-out):

```text
┌─────────────────────────────────────────────┐
│  features/     Screens & UI (what user sees) │
├─────────────────────────────────────────────┤
│  core/         Theme, router, shared widgets │
├─────────────────────────────────────────────┤
│  providers/    Riverpod “wiring”             │
├─────────────────────────────────────────────┤
│  services/     Business logic (no UI)        │
├─────────────────────────────────────────────┤
│  data/         Repositories + SQLite         │
├─────────────────────────────────────────────┤
│  domain/       Pure models & enums           │
└─────────────────────────────────────────────┘
```

**Dependency rule:** `features` → `providers` → `services` / `data` → `domain`.  
`domain` must not import Flutter UI or plugins.

### Entry flow

```text
main.dart
  └── ProviderScope
        └── WhisperBackApp (app.dart)
              ├── MaterialApp.router + themes (light/dark)
              ├── scheduleEngineProvider.start()  ← interval firing
              └── go_router (app_router.dart)
```

---

## 9. Core concepts for mobile beginners

### Widget

Everything on screen is a **Widget** (class extending `StatelessWidget` or `StatefulWidget`). You **compose** small widgets into screens—similar to React components.

### Build method

`build(BuildContext context)` returns the widget tree. Flutter redraws when state changes.

### StatefulWidget vs StatelessWidget

- **Stateless:** UI that only depends on inputs (`final` fields).
- **Stateful:** Internal state (timers, form fields, animations) in a `State<T>` class.

### async / await

Database and file I/O are asynchronous. UI code uses `Future<void>` and `async`/`await`; Riverpod `FutureProvider` exposes async data to widgets.

### Hot reload vs restart

- **Reload (`r`):** Fast; keeps app state; may not reset init code.
- **Restart (`R`):** Full app restart; use after changing `main()`, providers, or native config.

### Platform channels

Plugins (`record`, `geolocator`, etc.) talk to Android/iOS native APIs. You rarely write platform code in Phase 1—packages handle it.

---

## 10. Data layer: SQLite and repositories

**Storage:** `sqflite` (SQLite on device), **not** Drift—despite an outdated mention in the root `README.md`.

| Piece | File | Role |
|-------|------|------|
| Schema | `data/database/database_helper.dart` | Tables: `clips`, `playlists`, `playlist_clips`, `schedules`, `sleep_windows`, `prayer_settings`, `app_state` |
| Seed data | `data/database/seed_service.dart` | Demo content on first launch |
| Repositories | `data/repositories/*.dart` | CRUD per entity; UI never writes SQL directly |

**Repository pattern:** Screens call `ref.watch(playlistRepositoryProvider)` or higher-level providers like `playlistsProvider`, not raw SQL.

**Phase 2:** `data/repositories/cloud/README.md` describes swapping in sync implementations behind the same interfaces.

---

## 11. Playback: the heart of the product

Read **`docs/playback-states.md`** in full—it is the product contract.

### Priority (highest wins)

1. App **Inactive** → nothing plays  
2. **Sleep / Prayer** → pause everything  
3. **Scheduled** playback  
4. **Manual** playback (user pressed Play)

### Key files

| File | Role |
|------|------|
| `domain/playback/playback_state.dart` | Enum: `inactive`, `activeIdle`, `manualPlaying`, `scheduledPlaying`, `sleepPaused`, `prayerPaused` |
| `services/playback/playback_coordinator.dart` | Enforces priority; drives `just_audio` |
| `services/audio/audio_services.dart` | `AudioPlaybackService`, recording, import |
| `services/shuffle/shuffle_engine.dart` | Per-playlist shuffle order |
| `features/playback/playback_modal.dart` | S13 UI |
| `providers/playback_providers.dart` | Exposes coordinator + `playbackSnapshotProvider` stream |

### Audio package

- **`just_audio`:** Plays local files from paths stored in SQLite.
- **`audio_service`:** In pubspec for **background/lock-screen** playback—planned hardening (see audit); not fully wired in Phase 1 scaffold.

### Playback modal behavior (S13)

Per spec and client preview:

- Bottom sheet with playlist name, clip name, play/pause/stop, shuffle, close (top-right).
- **Closing the modal should not always stop audio**—user can navigate while listening; shell hosts the modal (`main_shell.dart`).

---

## 12. Scheduling, sleep, and prayer

### Schedule engine

`services/scheduler/schedule_engine.dart`:

- Started from `app.dart` on launch (`scheduleEngineProvider.start()`).
- Polls every **15 seconds**, checks enabled schedules, calls `PlaybackCoordinator.playPlaylist(..., fromSchedule: true)`.
- **Conflict detection** when saving schedules: `ScheduleEngine` / repository logic + UI dialog on S08.

**Platform note:** Android can be more exact with foreground service + alarms; iOS may drift ±1–2 minutes—disclose in Settings (`qa-checklist.md`).

### Sleep mode

`features/sleep/sleep_mode_screen.dart` + `sleep_repository.dart` — time windows that force `sleepPaused` in the coordinator.

### Prayer mode

`services/prayer/prayer_service.dart` uses **`adhan`** (offline calculation) + **`geolocator`** for GPS. Location stays on device (spec). Pauses playback during prayer windows.

---

## 13. State management with Riverpod

**Package:** `flutter_riverpod`

| Pattern | Example in project |
|---------|-------------------|
| `Provider` | Singleton services (`playbackCoordinatorProvider`) |
| `FutureProvider` | Load lists (`playlistsProvider`, `clipsProvider`) |
| `StreamProvider` | Playback snapshot stream |
| `ConsumerWidget` / `ConsumerStatefulWidget` | `WidgetRef ref` to read/watch providers |

**Example mental model:**

```dart
// In a screen:
final playlists = ref.watch(playlistsProvider);
return playlists.when(
  data: (list) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('$e'),
);
```

Providers are centralized in `lib/providers/` to keep features mostly UI-focused.

---

## 14. Navigation with go_router

**Package:** `go_router`

- Declarative routes in `app_router.dart`.
- `context.go('/home')` replaces stack; `context.push(...)` for stacks (e.g. detail screens).
- `ShellRoute` + `MainShell` keeps bottom navigation visible on main tabs.

**Splash → Home:** `splash_screen.dart` calls `context.go('/home')` after seed + delay.

---

## 15. Theming and matching `ui-preview.html`

| Token (preview / JSON) | Flutter |
|------------------------|---------|
| `--deep`, `--ink` | `AppColors.deep`, `AppColors.ink` |
| `--brand`, `--soft` | `AppColors.brand`, `AppColors.soft` |
| Glass cards | `WhisperCard`, `DepthSurface`, `PremiumScreenBackground` |
| Fraunces / DM Sans | `GoogleFonts` in `app_theme.dart` |
| Light/dark | `AppTheme.light` / `AppTheme.dark`; toggle in Settings (`themeModeProvider`) |

Icons: **Lucide** via `flutter_lucide` (`core/theme/app_icons.dart`).

When colors look “off,” compare side-by-side: browser preview vs emulator with the same theme (dark default).

---

## 16. Day-to-day development workflow

1. **Pick a screen** from sign-off list or `screen-specs.md`.
2. **Open preview** in `ui-preview.html`.
3. **Edit** `lib/features/...` and shared widgets if needed.
4. **Run** `flutter run`; use hot reload.
5. **Analyze:** `flutter analyze`
6. **Test:** `flutter test` (add tests for logic you touch—see `test/shuffle_engine_test.dart`).
7. **Compare** behavior to `docs/playback-states.md` and `qa-checklist.md`.

**CI:** `.github/workflows/mobile_ci.yml` runs analyze, test, and debug APK build on push to `mobile/`.

---

## 17. Testing and QA

| Layer | Command | Location |
|-------|---------|----------|
| Unit | `flutter test` | `mobile/test/` |
| Integration | `flutter test integration_test/` | `mobile/integration_test/` |
| Manual | `docs/qa-checklist.md` | Real devices (Samsung, Pixel, iPhone) |

Critical cases include background audio, schedule firing within tolerance, sleep/prayer interrupt, schedule conflict blocking save, and app-kill restart behavior.

---

## 18. Phase 1 vs Phase 2

| Phase 1 (now) | Phase 2 (later) |
|---------------|-----------------|
| Local SQLite | DynamoDB + sync API |
| No account required for core | Cognito auth (`/sign-in` UI exists as scaffold) |
| `just_audio` local files | S3 pre-signed upload/download |
| Stub `cloud/` repositories | Real sync in `data/repositories/cloud/` |
| — | `admin/` Next.js panel, `infra/` CDK |

API shapes are documented in `docs/api-contracts.md`—implement mobile clients against those paths when Phase 2 starts.

---

## 19. Known gaps (audit summary)

From `docs/PROJECT_AUDIT.md` (May 2026)—re-run audit after fixes:

| Area | Status / action |
|------|-----------------|
| `android/` / `ios/` folders | May be missing locally → run `flutter create .` |
| Flutter SDK on dev machine | Install if `flutter doctor` fails |
| Client sign-off screens | S02, S04, S08, S13 need polish vs preview |
| Background audio | `audio_service` not fully integrated |
| Demo clip assets | Seed may reference missing `asset://` files |
| Test coverage | Low; expand for coordinator + scheduler |
| Root README | Mentions Drift/build_runner—**outdated**; use `sqflite` + `flutter pub get` only |

Sprint priorities in the audit: unblock build → sign-off screens → release hardening (notifications, TestFlight/Play Internal).

---

## 20. Learning path (suggested order)

| Week | Focus | Resources |
|------|-------|-----------|
| 1 | Install Flutter, run app, explore preview HTML | This doc §4–5, [Flutter install](https://docs.flutter.dev/get-started/install) |
| 2 | Dart basics + Widget composition | [Dart language tour](https://dart.dev/language), tweak `home_screen.dart` |
| 3 | Navigation + one feature end-to-end | `app_router.dart`, `playlists_screen.dart` |
| 4 | Riverpod + repositories | `repository_providers.dart`, `playlistsProvider` |
| 5 | Playback + state machine | `playback-states.md`, `playback_coordinator.dart` |
| 6 | Schedule / sleep / prayer | `schedule_engine.dart`, `prayer_service.dart` |
| 7 | Tests + QA checklist | `qa-checklist.md`, write one widget test |

**Official Flutter codelabs:** [https://docs.flutter.dev/codelabs](https://docs.flutter.dev/codelabs)

---

## 21. Quick reference commands

```powershell
# From repo root — Windows setup helper
.\scripts\setup_mobile.ps1

cd D:\whisperback\whispherback\mobile

flutter doctor -v
flutter pub get
flutter create . --project-name whisperback --org com.whisperback   # if android/ missing
flutter devices
flutter run --dart-define=FLAVOR=dev
flutter analyze
flutter test
flutter build apk --debug --dart-define=FLAVOR=dev

# Open design reference (default browser)
start ..\design\ui-preview.html
```

---

## Related documents (read next)

| Document | Why |
|----------|-----|
| [design/screen-specs.md](../design/screen-specs.md) | Per-screen requirements |
| [design/ui-preview.html](../design/ui-preview.html) | Approved UI |
| [docs/playback-states.md](playback-states.md) | Playback rules |
| [docs/PROJECT_AUDIT.md](PROJECT_AUDIT.md) | What’s done vs missing |
| [docs/qa-checklist.md](qa-checklist.md) | Before release |
| [mobile/README.md](../mobile/README.md) | Short mobile readme |

---

*Questions or gaps in this walkthrough? Extend this file as you learn—especially Windows-specific fixes from `flutter doctor`.*

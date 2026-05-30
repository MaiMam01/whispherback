# WhisperBack Design System

## Figma

Create a Figma file matching [screen-specs.md](screen-specs.md) and link here:

`[Figma — WhisperBack v1]` _(add URL when file is created)_

## Tokens

Machine-readable tokens for Flutter theming: [tokens.json](tokens.json)

## Components (library checklist)

| Component | Used on | Notes |
|-----------|---------|-------|
| ActiveToggle | S02 Home | Rotating power button, purple glow when ON |
| NavBar | Shell | Icon-first; labels optional via Settings |
| PlaylistCard | S03 | Name, clip count, schedule/shuffle badges |
| ClipRow | S05 | Source icon, duration |
| ScheduleConflictDialog | S08 modal | Blocks save, names conflicting playlist |
| PlaybackModal | S13 | Bottom sheet; close top-right |
| ProgressBar | S07 Import | Real-time import progress |
| SleepTimer | S10 | Countdown + end early |
| PrayerMethodPicker | S11 | Method + madhab dropdowns |
| StatusChip | S02 | Sleep/prayer active indicator |

## Client sign-off (required before pixel-perfect polish)

- [ ] S02 Home — Active toggle
- [ ] S04 Playlist detail
- [ ] S08 Schedule builder
- [ ] S13 Playback modal

# WhisperBack — Screen Specifications

Design reference for Flutter implementation. Figma file to be linked when available.

## Global UX rules (from Features Document v1.0)

- **Icon-first UI** with optional "Show labels" in Settings
- **Dark-first** purple theme (`#1A1240` background)
- Minimum touch target: **44pt**
- Playback uses **popup modal**, not full-screen player
- Close button **top-right** on all modals/popups
- Home screen: **one central ON/OFF** — no shuffle on home
- Sleep icon = **Zzz** on home screen

---

## S01 — Splash / First Launch

| Property | Value |
|----------|-------|
| Route | `/` |
| Duration | 1.5s auto-advance |
| Content | Logo "W", tagline, purple gradient background |
| First launch | Optional 3 coach marks → Home |

---

## S02 — Home (Critical — client sign-off)

| Property | Value |
|----------|-------|
| Route | `/home` |
| Primary control | Large circular **Active/Inactive** toggle, center |
| Active state | Purple glow, subtle rotation animation on toggle |
| Inactive state | Muted grey, no glow |
| Secondary | **Zzz** sleep mode shortcut (bottom-left area) |
| Navigation | Bottom bar: Home · Playlists · Clips · Schedule · Settings |
| **Excluded** | Shuffle toggle (NOT on home) |

---

## S03 — Playlists List

| Route | `/playlists` |
| Shows | All playlists with name, clip count, duration |
| Indicators | Dot/badge if scheduled or currently playing |
| Actions | FAB → create playlist; tap → detail |
| Empty state | Illustration + "Create your first playlist" |

---

## S04 — Playlist Detail (Critical — client sign-off)

| Route | `/playlists/:id` |
| Shows | Clip list, total duration, shuffle toggle |
| Actions | Play (opens modal), Add clips, Edit schedule, Rename, Delete |
| Shuffle | Standard icon; white circle outline when ON |
| Delete guard | If schedule active → confirm dialog |

---

## S05 — Clip Library

| Route | `/clips` |
| Shows | All clips (recorded + imported) with duration |
| Actions | Record new, Import file, Add to playlist (multi-select) |
| Filter | All · Recorded · Imported |

---

## S06 — Record Audio

| Route | `/clips/record` |
| Shows | Waveform/level meter, timer, record/stop/save |
| Save flow | Name clip → saved to library |

---

## S07 — Import Audio

| Route | `/clips/import` |
| Shows | File picker trigger, **real-time progress bar** |
| Formats | MP3, M4A |
| Completion | Success toast + navigate to library |

---

## S08 — Schedule Builder (Critical — client sign-off)

| Route | `/schedule/build/:playlistId` |
| Fields | Start time, interval (minutes 1–60 or hours 1–24) |
| Validation | **Conflict detection** — block save, show warning |
| Preview | "Next clip at HH:MM" |

---

## S09 — Scheduled Overview

| Route | `/schedule` |
| Shows | Summary only: playlist name, created date, interval, shuffle status |
| **Excluded** | Clip-level details |

---

## S10 — Sleep Mode

| Route | `/sleep` |
| Fields | Start time, duration or end time |
| Active state | Countdown timer, "Sleep active until HH:MM" |
| Priority | Overrides all playback |

---

## S11 — Prayer Mode Settings

| Route | `/prayer` |
| Fields | Calculation method (default Karachi), Asr madhab |
| Location | GPS auto-detect OR manual city |
| Permission | Rationale dialog before location request |
| Privacy | GPS never leaves device |

---

## S12 — Settings

| Route | `/settings` |
| Toggles | Show labels, dark/light (system default) |
| Guides | Battery whitelist instructions (Samsung, Xiaomi, Huawei) |
| About | Version, privacy link placeholder |

---

## S13 — Playback Modal (Critical — client sign-off)

| Type | Bottom sheet / overlay modal |
| Shows | Playlist name, current clip name |
| Controls | Play · Pause · Stop · Shuffle · Close (top-right) |
| Behavior | Can close without stopping (optional setting) |
| Non-blocking | User can navigate while playing |

---

## Modals

| Modal | Trigger |
|-------|---------|
| Schedule conflict | Overlapping schedule save |
| Delete playlist + schedule | Delete with active schedule |
| Permission rationale | Mic, location, exact alarm, notifications |
| Import complete/error | Import finished |
| Sleep ending soon | Optional, 5 min before sleep ends |

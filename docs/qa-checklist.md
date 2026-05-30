# QA Checklist — Phase 1 Local MVP

Run on device matrix before TestFlight / Play Internal release.

## Device matrix

| Platform | Devices |
|----------|---------|
| Android | Samsung Galaxy, Xiaomi, OnePlus, Google Pixel |
| iOS | iPhone 12, iPhone 14, iPhone 16 |

## Critical test cases (must pass 9/9)

| # | Test | Pass criteria |
|---|------|---------------|
| TC-01 | Background audio — screen lock | Audio continues when screen locks on all 8 OS/device combos |
| TC-02 | Schedule trigger — Android | Clip fires within **30 seconds** of scheduled time |
| TC-03 | Schedule trigger — iOS | Clip fires within **3 minutes** (platform tolerance) |
| TC-04 | Sleep mode interrupt | Sleep pauses mid-playback; resumes when window ends |
| TC-05 | Prayer mode | GPS read → correct prayer time → pause → resume after window |
| TC-06 | Cloud sync (Phase 2) | Offline playlist on Device A → online → appears on Device B |
| TC-07 | 50-clip import | Progress shown; no freeze; no crash on mid-range device |
| TC-08 | Schedule conflict | Warning shown; save blocked; user prompted to adjust |
| TC-09 | App kill restart | Alarms re-register; Active state preserved; sleep windows active |

## Regression — UI flows

- [ ] S02 Home toggle animates and persists across restart
- [ ] S04 Playlist CRUD + shuffle toggle
- [ ] S08 Schedule builder conflict dialog
- [ ] S13 Playback modal — play/pause/stop/close
- [ ] Show labels mode in Settings affects all nav items
- [ ] Empty states on playlists, clips, schedules

## Performance

- [ ] Cold start < 2 seconds on mid-range Android
- [ ] No jank during 50-clip import progress updates
- [ ] Battery: foreground service notification visible on Android when Active

## Automated tests

```bash
cd mobile
flutter test
flutter test integration_test/
```

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Engineer | | | |
| Flutter Lead | | | |
| Client (Dr. Maria) | | | |

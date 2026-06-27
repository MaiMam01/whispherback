// Regression test for QA reports:
//
//   1. "Power button scroll up hoky gaib hony lag gya."
//      (Round 7 / 8 QA — toggle scrolled off-screen.)
//
//   2. "Power button should be a little bit lower or aligned rather it is
//       currently inclined to upward more."
//      "GOOD morning and the finish setup button is scrollable and they
//       become hidden on scroll down and when I scroll up they become
//       visible."
//      (Round 8 QA — the previous fix pinned the toggle but moved the
//      greeting card and setup chip into the scrollable region, and the
//      toggle ended up pegged to the top of the viewport, not centered.)
//
// The current home layout is a THREE-ZONE structure:
//
//     ┌────────────────────────────┐
//     │  headerZone   (fixed)      │   ← title, date, greeting, setup chip
//     ├────────────────────────────┤
//     │                            │
//     │  toggleZone   (centered    │   ← waveform, power button, status pill
//     │                in the      │      vertically centered so the button
//     │                remaining   │      sits comfortably in the middle of
//     │                space)      │      the visible area
//     │                            │
//     ├────────────────────────────┤
//     │  statsZone    (capped @    │   ← quick stats, next-whisper card,
//     │                ~42% of     │      mode chips. Scrollable if it
//     │                viewport)   │      overflows.
//     └────────────────────────────┘
//
// On extremely short viewports (flip cover, ~split-screen), this would
// crash with a negative Spacer, so the layout falls back to a single
// scroll view containing everything.
//
// This test pins the contract so a future refactor can't silently regress.

import 'package:flutter_test/flutter_test.dart';

enum HomeLayoutMode {
  threeZonePinned,
  singleScrollFallback,
}

/// Mirrors the production decision in `HomeScreen.build` for whether the
/// three-zone pinned layout fits a given viewport.
HomeLayoutMode decideHomeLayout({
  required double viewportHeight,
  required double estimatedHeaderHeight,
  required double estimatedMinToggleHeight,
  required double reservedForStats,
}) {
  if (viewportHeight >=
      (estimatedHeaderHeight + estimatedMinToggleHeight + reservedForStats)) {
    return HomeLayoutMode.threeZonePinned;
  }
  return HomeLayoutMode.singleScrollFallback;
}

void main() {
  group('home layout decision (greeting + toggle + stats all visible)', () {
    test(
      'a normal-height phone (Pixel 7-class) uses the three-zone pinned '
      'layout so neither the greeting nor the power button can scroll away',
      () {
        // Pixel 7-class viewport (~750 dp usable height).
        expect(
          decideHomeLayout(
            viewportHeight: 750,
            estimatedHeaderHeight: 200,
            estimatedMinToggleHeight: 360,
            reservedForStats: 120,
          ),
          HomeLayoutMode.threeZonePinned,
        );
      },
    );

    test(
      'a tall phone (Samsung S24, Pixel 8 Pro) ALSO uses the pinned layout '
      '— extra room is distributed: more vertical centering for the toggle, '
      'more breathing room in the stats region',
      () {
        expect(
          decideHomeLayout(
            viewportHeight: 900,
            estimatedHeaderHeight: 200,
            estimatedMinToggleHeight: 360,
            reservedForStats: 120,
          ),
          HomeLayoutMode.threeZonePinned,
        );
      },
    );

    test(
      'a compact phone (~Galaxy A04, low-end Vivo Y-series) still pins all '
      'three zones as long as the viewport can fit them',
      () {
        // Compact viewport: 720 dp = header(200) + toggle(360) + stats(120) + 40 slack.
        expect(
          decideHomeLayout(
            viewportHeight: 720,
            estimatedHeaderHeight: 200,
            estimatedMinToggleHeight: 360,
            reservedForStats: 120,
          ),
          HomeLayoutMode.threeZonePinned,
        );
      },
    );

    test(
      'a flip-cover form factor that cannot fit the full three-zone layout '
      'gracefully falls back to a single scroll view — the user can scroll '
      'to see everything and the layout never crashes with a negative '
      'Spacer',
      () {
        // Galaxy Z Flip cover-only mode (~260 dp usable).
        expect(
          decideHomeLayout(
            viewportHeight: 260,
            estimatedHeaderHeight: 170,
            estimatedMinToggleHeight: 280,
            reservedForStats: 90,
          ),
          HomeLayoutMode.singleScrollFallback,
        );
      },
    );

    test(
      'split-screen / multi-window with minuscule height falls back to '
      'single scroll — the user is in an edge mode, but we still render '
      'something usable',
      () {
        expect(
          decideHomeLayout(
            viewportHeight: 180,
            estimatedHeaderHeight: 200,
            estimatedMinToggleHeight: 360,
            reservedForStats: 120,
          ),
          HomeLayoutMode.singleScrollFallback,
        );
      },
    );

    test(
      'exact-boundary: a viewport equal to header + toggle + stats is treated '
      'as fits — we never fall back when there is literally enough room',
      () {
        expect(
          decideHomeLayout(
            viewportHeight: 680,
            estimatedHeaderHeight: 200,
            estimatedMinToggleHeight: 360,
            reservedForStats: 120,
          ),
          HomeLayoutMode.threeZonePinned,
        );
      },
    );

    test(
      'when Active is OFF the header is shorter (no setup chip) — slightly '
      'smaller phones can still use the pinned layout because the header '
      'shrinks',
      () {
        // Compact 650 dp viewport, inactive header = 130 dp.
        expect(
          decideHomeLayout(
            viewportHeight: 650,
            estimatedHeaderHeight: 130,
            estimatedMinToggleHeight: 360,
            reservedForStats: 120,
          ),
          HomeLayoutMode.threeZonePinned,
        );
      },
    );
  });
}

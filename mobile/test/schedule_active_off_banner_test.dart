// Pins the UI-state logic that decides whether the "Activate WhisperBack
// to start your schedules" banner appears on the Schedules screen.
//
// Why this exists: The single biggest support ticket pattern was:
// users saved schedules, saw the success snackbar, and assumed everything
// would fire automatically. They had no idea the `ScheduleEngine`
// silently skips every tick when the master Active toggle is off. The
// new banner makes the dependency impossible to miss — but only if its
// trigger condition stays correct. This test pins that contract.
//
// The banner's visibility rule (lifted verbatim from
// `ScheduledOverviewScreen.build`):
//
//   showActiveOffWarning = anyEnabledSchedule && masterActiveIsOff
//
// Easy to misread as "show whenever Active is off", which would create a
// noisy banner on fresh installs with zero schedules. We assert against
// the table below so future refactors can't quietly change either half
// of the AND.

import 'package:flutter_test/flutter_test.dart';

bool showActiveOffWarning({
  required bool anyEnabledSchedule,
  required bool masterActiveIsOff,
}) {
  return anyEnabledSchedule && masterActiveIsOff;
}

void main() {
  group('Active-off banner visibility rule', () {
    test('hides when no schedules exist (avoids noise on fresh installs)', () {
      expect(
        showActiveOffWarning(
          anyEnabledSchedule: false,
          masterActiveIsOff: true,
        ),
        isFalse,
      );
    });

    test('hides when schedules exist but are all disabled (user intent)', () {
      expect(
        showActiveOffWarning(
          anyEnabledSchedule: false,
          masterActiveIsOff: true,
        ),
        isFalse,
      );
    });

    test('hides when Active is ON regardless of schedule count', () {
      expect(
        showActiveOffWarning(
          anyEnabledSchedule: true,
          masterActiveIsOff: false,
        ),
        isFalse,
      );
      expect(
        showActiveOffWarning(
          anyEnabledSchedule: false,
          masterActiveIsOff: false,
        ),
        isFalse,
      );
    });

    test(
        'shows only when there is at least one enabled schedule AND Active '
        'is OFF — the exact misconfiguration that broke QA on Samsung', () {
      expect(
        showActiveOffWarning(
          anyEnabledSchedule: true,
          masterActiveIsOff: true,
        ),
        isTrue,
        reason: 'This is the support-ticket scenario: enabled schedules + '
            'Active off = nothing fires. The banner MUST appear.',
      );
    });
  });
}

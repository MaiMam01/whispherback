// Pins that `ScheduleEngine._failureBackoff` is an INSTANCE field, not a
// static one. The previous static map persisted across engine rebuilds
// (e.g. provider invalidation, fresh app launch within a hot-reload
// session) so a single failed fire poisoned the engine for the rest of
// the process. Combined with the now-removed aggressive 2s warmup
// deadline that threw on slow Samsung devices, this is why QA reported
// "schedules never fire after the first failed attempt".
//
// We can't easily instantiate the production `ScheduleEngine` in the VM
// suite because it pulls in Riverpod providers + DB. Instead, we
// re-derive the contract from the production source so the test fails
// if anyone changes `_failureBackoff` back to `static`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
      'ScheduleEngine._failureBackoff is an INSTANCE field — a static map '
      'leaks cooldowns across rebuilds and causes "schedules never fire"', () {
    final enginePath = p.join(
      Directory.current.path,
      'lib',
      'services',
      'scheduler',
      'schedule_engine.dart',
    );
    final source = File(enginePath).readAsStringSync();

    // The bad pattern. If anyone reintroduces `static final` on
    // `_failureBackoff`, this test catches it.
    expect(
      source.contains(RegExp(
          r'static\s+final\s+Map<String,\s*DateTime>\s+_failureBackoff')),
      isFalse,
      reason: '`_failureBackoff` must NOT be static. A static cooldown map '
          'persists across ScheduleEngine rebuilds, so a single '
          'decodeFailed during the session keeps the schedule blocked for '
          'a full minute even AFTER the underlying issue is resolved. '
          'This was a contributor to the "schedules never fire" QA '
          'report. Keep it as `final Map<String, DateTime> _failureBackoff`'
          '.',
    );

    expect(
      source.contains(
          RegExp(r'final\s+Map<String,\s*DateTime>\s+_failureBackoff')),
      isTrue,
      reason: 'The instance-level backoff field MUST exist — it is what '
          'prevents the engine from hammering an empty playlist every 5s.',
    );
  });

  test(
      'ScheduleEngine.start() uses a 5-second periodic tick — the cadence '
      'that the failure-backoff math (1 minute) and the maxLateness '
      '(90 seconds) were both designed against', () {
    // Pin the tick interval as code. If someone reduces it to e.g. 1
    // second, the backoff will burn through retries 5x faster and the
    // notification rate-limiter on the home screen will start to drop
    // updates; if someone raises it to 30s, scheduled fires can lag past
    // the 90s grace window and silently skip slots. Either regression
    // would land back in the QA report.
    final enginePath = p.join(
      Directory.current.path,
      'lib',
      'services',
      'scheduler',
      'schedule_engine.dart',
    );
    final source = File(enginePath).readAsStringSync();
    expect(
      source.contains(
          RegExp(r"Timer\.periodic\(\s*const\s+Duration\(seconds:\s*5\)")),
      isTrue,
      reason: 'Schedule engine periodic tick interval is part of the '
          'fire-timing contract. Changing it requires re-deriving the '
          'failure backoff and lateness constants.',
    );
  });
}

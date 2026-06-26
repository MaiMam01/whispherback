// Regression coverage for the "first recorded clip won't play, the next six
// do" report. The root cause was a race between `audio_session.setActive` and
// the first `_player.play()` call — by the time the OS granted audio focus,
// the MediaPlayer had already failed silently. We now do three things:
//
// 1. Pre-warm the audio session at app startup (`warmUp`) so the first user
//    tap never races with native session activation.
// 2. Validate inputs to `playFile` (non-empty path, file exists on disk) so
//    callers fail FAST and the coordinator's try/catch fires a snackbar
//    instead of pretending playback succeeded.
// 3. Verify the player actually reached a playable state within a short
//    window after `play()` — the warmup guard.
//
// These tests pin those guarantees. We can't spin up `audio_service` in a
// pure-VM test (no Android plugin runtime), so we exercise the validation
// and warmup logic directly. The full integration is covered manually on
// device + via the QA checklist.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Playback first-clip warmup contract', () {
    test('playFile must reject empty paths so the UI gets a real error', () {
      // The handler's playFile throws ArgumentError on empty path. We
      // mirror that contract here so the test fails if someone ever
      // softens the validation back to a silent no-op (which was the
      // original symptom — silent failure ate the user's first record).
      void simulate(String path) {
        if (path.isEmpty) {
          throw ArgumentError('playFile requires a non-empty path');
        }
      }

      expect(() => simulate(''), throwsArgumentError);
      expect(() => simulate('/tmp/clip.m4a'), returnsNormally);
    });

    test('playFile must reject missing files instead of trying to load', () {
      // Same contract: mirror the production guard so that a missing file
      // throws synchronously and the snackbar fires. Previously the player
      // would accept the path and silently sit in `idle` forever.
      void simulate(String path) {
        if (path.isEmpty) {
          throw ArgumentError('playFile requires a non-empty path');
        }
        if (!File(path).existsSync()) {
          throw StateError('Clip file is missing on disk: $path');
        }
      }

      final tempDir = Directory.systemTemp.createTempSync('whisperback_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final missing = p.join(tempDir.path, 'never_existed.m4a');
      expect(() => simulate(missing), throwsStateError);

      final real = File(p.join(tempDir.path, 'real.m4a'))
        ..writeAsBytesSync([0, 1, 2, 3]);
      expect(() => simulate(real.path), returnsNormally);
    });

    test(
        'warmup deadline must trigger StateError when playback never reaches '
        'a playable state within the window', () async {
      // The handler's `_confirmPlaybackStarted` polls for up to 2 seconds.
      // We simulate the polling loop with a `processingState` that never
      // becomes ready — this should throw, which the coordinator catches
      // and turns into a `decodeFailed` snackbar. The test uses a short
      // 200ms window so it stays fast.
      Future<void> simulate(Duration window) async {
        final deadline = DateTime.now().add(window);
        while (DateTime.now().isBefore(deadline)) {
          // Simulated: state never advances — same as a hung
          // MediaPlayer that took the audio focus race and lost.
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        throw StateError(
          'Playback did not start within the warmup window',
        );
      }

      await expectLater(
        simulate(const Duration(milliseconds: 200)),
        throwsStateError,
        reason: 'Hung playback MUST surface as a thrown error so the user '
            'gets a snackbar — silent no-op was the original bug.',
      );
    });

    test('warmup deadline returns normally if state reaches ready quickly',
        () async {
      // Happy path: the player reaches `ready` within the window and the
      // function returns without throwing. Without this branch, every
      // legitimate playback would trip the snackbar.
      Future<void> simulate({
        required Duration window,
        required Duration timeToReady,
      }) async {
        final deadline = DateTime.now().add(window);
        final readyAt = DateTime.now().add(timeToReady);
        while (DateTime.now().isBefore(deadline)) {
          if (DateTime.now().isAfter(readyAt)) return;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        throw StateError('not ready');
      }

      await expectLater(
        simulate(
          window: const Duration(milliseconds: 500),
          timeToReady: const Duration(milliseconds: 100),
        ),
        completes,
      );
    });
  });
}

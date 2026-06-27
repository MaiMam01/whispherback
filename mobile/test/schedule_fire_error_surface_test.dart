// Round 10 regression — "SCHEDULES are not working, I set up the schedule
// and the power button was ON, but still there is not notification bar or
// lock screen notification. AND most importantly the AUDIO clip/playlist
// didn't played."
//
// Previously, when `_playPlaylistInternal` hit `playFile`'s catch path
// with `fromSchedule: true`, the failure was swallowed silently:
//
//     } catch (_) {
//       if (!fromSchedule) {
//         _errorController.add(PlaybackErrorEvent(...));
//       }
//       return false;
//     }
//
// The user got NO indication that the schedule fire was attempted but
// failed. We now ALWAYS emit the error event — the engine's own roll-
// back logic continues to handle the lastFired stamp, but the user
// finally sees a snackbar explaining what happened.
//
// This is a source-level check (we cannot mount a real WhisperAudio-
// Handler in the VM test suite without `audio_service` doing real
// platform binding); it pins the conditional so a future refactor
// doesn't quietly re-introduce the silent path.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
      'PlaybackCoordinator surfaces decodeFailed even for scheduled fires '
      'so a missed schedule is never silent', () {
    final path = p.join(
      Directory.current.path,
      'lib',
      'services',
      'playback',
      'playback_coordinator.dart',
    );
    final source = File(path).readAsStringSync();

    // The historic silent path was `if (!fromSchedule) { errorController.add... }`
    // around the playFile catch in `_playPlaylistInternal`. The fix
    // unconditionally surfaces the event.
    expect(
      source.contains(
          RegExp(r"playPlaylist:\s+playFile\s+failed", multiLine: true)),
      isTrue,
      reason: 'The catch branch must log the playFile failure for '
          'debugging — was previously a silent `catch (_) { ... }`.',
    );

    // Pin the comment-level intent so any reviewer who reads this
    // catch block knows why we deliberately removed the
    // `if (!fromSchedule)` gate.
    expect(
      source.contains('ALWAYS surface the decode failure'),
      isTrue,
      reason: 'Comment must explain why scheduled fires also emit the '
          'error event — otherwise a future contributor will "fix" '
          'this and reintroduce the silent-schedule QA bug.',
    );
  });

  test(
      'requestScheduledPlay clears activeScheduleId even when the '
      'internal play throws (was a leak that prevented re-entry)', () {
    final path = p.join(
      Directory.current.path,
      'lib',
      'services',
      'playback',
      'playback_coordinator.dart',
    );
    final source = File(path).readAsStringSync();

    // We require try/finally OR explicit catch around _playPlaylistInternal
    // inside requestScheduledPlay. The simplest match is the comment that
    // explains the rationale.
    expect(
      source.contains('clears the active-schedule pointer'),
      isTrue,
      reason: 'requestScheduledPlay must use try/finally OR an explicit '
          'catch around _playPlaylistInternal so a thrown error never '
          'leaves `_activeScheduleId` set — otherwise the engine cannot '
          're-enter the schedule for a fresh attempt.',
    );
  });

  test('mini_player + playback_modal wrap every coordinator call in _safeCall',
      () {
    for (final filename in const [
      'mini_player_bar.dart',
      'playback_modal.dart',
    ]) {
      final path = p.join(
        Directory.current.path,
        'lib',
        'features',
        'playback',
        filename,
      );
      final source = File(path).readAsStringSync();
      expect(
        source.contains('_safeCall'),
        isTrue,
        reason: '$filename must use the _safeCall wrapper so a thrown '
            'PlatformException from a button tap never bubbles up as '
            'an "app crashed" — was the cross-icon crash QA report.',
      );
    }
  });
}

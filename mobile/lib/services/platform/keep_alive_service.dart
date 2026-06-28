import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the native Android [WhisperKeepAliveService] that owns the
/// process lifecycle independently of `audio_service` and `just_audio`.
///
/// Calling [start] launches a native Android foreground service that:
///   * Holds a partial wake lock (`PARTIAL_WAKE_LOCK`), so the CPU keeps
///     running even when the screen is off — required for `Timer.periodic`
///     in the Dart isolate to actually tick at the right cadence.
///   * Posts a high-priority ongoing notification so the OS recognises the
///     process as user-visible and the OEM battery manager
///     (Samsung One UI 6 / Vivo Funtouch 14 / Xiaomi MIUI 14) cannot reap
///     it after task removal.
///   * Uses `START_STICKY` so the OS re-creates the service if it does get
///     killed.
///   * Overrides `onTaskRemoved` to a no-op so the service stays alive after
///     the user swipes the activity away.
///
/// Calling [stop] tears the service down so the OS reclaims the wake lock
/// and the user's status bar is no longer occupied.
///
/// This is a complement to — not a replacement for — `audio_service`'s own
/// foreground service. `audio_service` handles the MediaSession, lock-screen
/// controls, and the actual audio output. The keep-alive service exists
/// solely to keep the host process alive between scheduled fires on devices
/// that don't honor `audio_service`'s silence keep-alive (volume-0 playback
/// is misclassified as "not playing" by some OEM audio policy daemons).
///
/// Best-effort: every call swallows errors so a missing platform channel
/// (iOS, web, integration tests) is a silent no-op.
abstract final class KeepAliveService {
  static const MethodChannel _channel =
      MethodChannel('com.whisperback.keep_alive');

  /// Starts the native FG service. Safe to call repeatedly — the underlying
  /// service handles `startForegroundService` idempotently.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('start');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('KeepAliveService.start failed: $e\n$st');
      }
    }
  }

  /// Stops the native FG service. Safe to call when not started.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('KeepAliveService.stop failed: $e\n$st');
      }
    }
  }
}

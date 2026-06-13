import '../../data/repositories/app_state_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../audio/whisper_audio_handler.dart';
import '../scheduler/schedule_fire_helper.dart';
import '../scheduler/schedule_last_fired_store.dart';
import 'notification_service.dart';

/// Reconciles notifications with app state.
///
/// • **Idle + Active** → flutter status notification (schedule summary)
/// • **Clip playing** → hide flutter status; [audio_service] owns the
///   Spotify-style media notification (play/pause/stop + lock screen)
Future<void> syncWhisperNotifications({
  required AppStateRepository appState,
  required ScheduleRepository schedules,
}) async {
  final service = NotificationService.instance;
  await service.init();

  final active = await appState.isActive();
  final all = await schedules.getAll();
  final enabled = all.where((s) => s.enabled).toList();
  final armed = enabled.length;
  final now = DateTime.now();
  final lastFired = ScheduleLastFiredStore.instance;
  final handler = whisperAudioHandler;
  final playingClip = handler.isPlayingClip;

  final upcoming = ScheduleFireHelper.upcomingEvents(
    enabled,
    now,
    lastFiredFor: lastFired.get,
    limit: 4,
  );

  String? nextUpcoming;
  String? upcomingSummary;
  if (upcoming.isNotEmpty) {
    nextUpcoming =
        'Next: “${upcoming.first.playlistName}” at ${_formatTime(upcoming.first.when)}';
    if (upcoming.length > 1) {
      upcomingSummary = upcoming
          .take(4)
          .map((e) => '• ${_formatTime(e.when)} — ${e.playlistName}')
          .join('\n');
    }
  }

  if (active && !playingClip) {
    final subtitle = nextUpcoming ??
        (armed > 0
            ? '$armed schedule(s) armed · whispers will play automatically'
            : 'Listening for scheduled whispers');
    await handler.updateActiveSessionInfo(
      subtitle: subtitle,
      scheduleCount: armed,
    );
    await service.showActiveOngoing(
      scheduleCount: armed,
      nextUpcoming: nextUpcoming,
      upcomingSummary: upcomingSummary,
    );
  } else if (playingClip) {
    // Do not touch handler media session — playFile owns it.
    // Hide the flutter status card so the media notification is unobstructed.
    await service.cancelActiveOngoing();
    if (!whisperAudioServiceBound) {
      await service.showNowPlaying(
        title: handler.currentClipTitle ?? 'Now playing',
        subtitle: active ? nextUpcoming : 'Library preview',
      );
    }
  } else {
    await service.cancelActiveOngoing();
  }

  await service.syncSchedules(all, active: active);
}

String _formatTime(DateTime when) {
  final h = when.hour;
  final m = when.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

Future<void> refreshWhisperNotifications({
  required AppStateRepository appState,
  required ScheduleRepository schedules,
}) =>
    syncWhisperNotifications(appState: appState, schedules: schedules);

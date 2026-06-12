import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/schedule_repository.dart';
import '../../domain/playback/playback_state.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';
import '../notifications/notification_sync.dart';
import '../playback/playback_coordinator.dart';
import 'schedule_fire_helper.dart';
import 'schedule_last_fired_store.dart';

typedef ScheduleNotificationSync = Future<void> Function();

/// Fires scheduled clip playback at interval boundaries.
class ScheduleEngine {
  ScheduleEngine({
    required ScheduleRepository scheduleRepository,
    required PlaybackCoordinator coordinator,
    required ScheduleLastFiredStore lastFiredStore,
    this.onNotificationsSync,
  })  : _schedules = scheduleRepository,
        _coordinator = coordinator,
        _lastFired = lastFiredStore;

  final ScheduleRepository _schedules;
  final PlaybackCoordinator _coordinator;
  final ScheduleLastFiredStore _lastFired;
  final ScheduleNotificationSync? onNotificationsSync;
  Timer? _timer;

  bool _started = false;

  void start() {
    _timer?.cancel();
    _started = true;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  void stop() {
    _started = false;
    _timer?.cancel();
  }

  bool get isRunning => _started;

  Future<void> _tick() async {
    // Only skip while a scheduled whisper is already playing — manual preview
    // must be interrupted when the next interval is due.
    if (_coordinator.snapshot.state == AppPlaybackState.scheduledPlaying &&
        _coordinator.snapshot.isPlaying) {
      return;
    }

    final all = await _schedules.getAll();
    final now = DateTime.now();

    for (final schedule in all) {
      final last = _lastFired.get(schedule.id);
      final slot = ScheduleFireHelper.slotToFire(schedule, now, last);
      if (slot == null) continue;

      await _lastFired.set(schedule.id, slot);
      await _coordinator.requestScheduledPlay(schedule.playlistId);
      await onNotificationsSync?.call();
      break;
    }
  }
}

final scheduleNotificationSyncProvider = Provider<ScheduleNotificationSync>(
  (ref) => () async {
    await syncWhisperNotifications(
      appState: ref.read(appStateRepositoryProvider),
      schedules: ref.read(scheduleRepositoryProvider),
    );
  },
);

final scheduleEngineProvider = Provider<ScheduleEngine>((ref) {
  final engine = ScheduleEngine(
    scheduleRepository: ref.watch(scheduleRepositoryProvider),
    coordinator: ref.watch(playbackCoordinatorProvider),
    lastFiredStore: ScheduleLastFiredStore.instance,
    onNotificationsSync: () => ref.read(scheduleNotificationSyncProvider)(),
  );
  ref.onDispose(engine.stop);
  return engine;
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/schedule_repository.dart';
import '../../domain/entities/playback_schedule.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';
import '../playback/playback_coordinator.dart';

/// Fires scheduled clip playback at interval boundaries.
class ScheduleEngine {
  ScheduleEngine({
    required ScheduleRepository scheduleRepository,
    required PlaybackCoordinator coordinator,
  })  : _schedules = scheduleRepository,
        _coordinator = coordinator;

  final ScheduleRepository _schedules;
  final PlaybackCoordinator _coordinator;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _tick() async {
    final all = await _schedules.getAll();
    final now = DateTime.now();
    for (final schedule in all) {
      if (_shouldFire(schedule, now)) {
        await _coordinator.playPlaylist(schedule.playlistId);
      }
    }
  }

  bool _shouldFire(PlaybackSchedule schedule, DateTime now) {
    if (schedule.startTime.isAfter(now)) return false;
    final elapsed = now.difference(schedule.startTime).inMinutes;
    if (elapsed < 0) return false;
    return elapsed % schedule.intervalMinutes == 0 && now.second < 20;
  }
}

final scheduleEngineProvider = Provider<ScheduleEngine>((ref) {
  final engine = ScheduleEngine(
    scheduleRepository: ref.watch(scheduleRepositoryProvider),
    coordinator: ref.watch(playbackCoordinatorProvider),
  );
  ref.onDispose(engine.stop);
  return engine;
});

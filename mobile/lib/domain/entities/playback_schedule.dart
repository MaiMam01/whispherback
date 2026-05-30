import 'package:equatable/equatable.dart';

class PlaybackSchedule extends Equatable {
  const PlaybackSchedule({
    required this.id,
    required this.playlistId,
    required this.startTime,
    required this.intervalMinutes,
    this.shuffleEnabled = false,
    this.enabled = true,
    this.playlistName = '',
  });

  final String id;
  final String playlistId;
  final DateTime startTime;
  final int intervalMinutes;
  final bool shuffleEnabled;
  final bool enabled;
  final String playlistName;

  String get intervalLabel {
    if (intervalMinutes >= 60 && intervalMinutes % 60 == 0) {
      final h = intervalMinutes ~/ 60;
      return h == 1 ? '1 hour' : '$h hours';
    }
    return '$intervalMinutes min';
  }

  @override
  List<Object?> get props => [
        id,
        playlistId,
        startTime,
        intervalMinutes,
        shuffleEnabled,
        enabled,
        playlistName,
      ];
}

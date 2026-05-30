import 'package:equatable/equatable.dart';

enum PlaybackPriority {
  inactive,
  sleepOrPrayer,
  scheduled,
  manual,
}

enum AppPlaybackState {
  inactive,
  activeIdle,
  manualPlaying,
  scheduledPlaying,
  sleepPaused,
  prayerPaused,
}

class PlaybackSnapshot extends Equatable {
  const PlaybackSnapshot({
    required this.state,
    this.playlistId,
    this.playlistName,
    this.clipTitle,
    this.isPlaying = false,
    this.shuffleEnabled = false,
  });

  final AppPlaybackState state;
  final String? playlistId;
  final String? playlistName;
  final String? clipTitle;
  final bool isPlaying;
  final bool shuffleEnabled;

  bool get canPlay =>
      state == AppPlaybackState.activeIdle ||
      state == AppPlaybackState.manualPlaying ||
      state == AppPlaybackState.scheduledPlaying;

  PlaybackSnapshot copyWith({
    AppPlaybackState? state,
    String? playlistId,
    String? playlistName,
    String? clipTitle,
    bool? isPlaying,
    bool? shuffleEnabled,
  }) {
    return PlaybackSnapshot(
      state: state ?? this.state,
      playlistId: playlistId ?? this.playlistId,
      playlistName: playlistName ?? this.playlistName,
      clipTitle: clipTitle ?? this.clipTitle,
      isPlaying: isPlaying ?? this.isPlaying,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    );
  }

  @override
  List<Object?> get props => [
        state,
        playlistId,
        playlistName,
        clipTitle,
        isPlaying,
        shuffleEnabled,
      ];
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/playback/playback_state.dart';
import '../../providers/playback_providers.dart';

class PlaybackModal extends ConsumerWidget {
  const PlaybackModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackSnapshotProvider);
    final snapshot = playback.valueOrNull;
    if (snapshot == null ||
        snapshot.state == AppPlaybackState.inactive ||
        snapshot.state == AppPlaybackState.activeIdle ||
        snapshot.playlistName == null) {
      return const SizedBox.shrink();
    }

    final coordinator = ref.read(playbackCoordinatorProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        child: Material(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot.playlistName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.soft,
                            ),
                          ),
                          Text(
                            snapshot.clipTitle ?? '',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () => coordinator.stop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.brand),
                      iconSize: 32,
                      onPressed: () {
                        if (snapshot.isPlaying) {
                          coordinator.pause();
                        } else {
                          coordinator.resume();
                        }
                      },
                      icon: Icon(
                        snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: coordinator.stop,
                      icon: const Icon(Icons.stop_circle_outlined, color: AppColors.gold),
                    ),
                    if (snapshot.playlistId != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => coordinator.toggleShuffle(
                          snapshot.playlistId!,
                          !snapshot.shuffleEnabled,
                        ),
                        icon: Icon(
                          Icons.shuffle,
                          color: snapshot.shuffleEnabled
                              ? AppColors.gold
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

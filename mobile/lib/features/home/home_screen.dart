import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/playback/playback_state.dart';
import '../../providers/playback_providers.dart';
import '../playback/playback_modal.dart';
import '../widgets/active_toggle.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackSnapshotProvider);
    final snapshot = playback.valueOrNull ??
        const PlaybackSnapshot(state: AppPlaybackState.inactive);
    final isActive = snapshot.state != AppPlaybackState.inactive;

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WhisperBack',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.soft,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sleep mode',
                      onPressed: () => context.push('/sleep'),
                      icon: const Icon(Icons.bedtime_outlined, color: AppColors.gold),
                    ),
                  ],
                ),
                const Spacer(),
                ActiveToggle(
                  isActive: isActive,
                  onToggle: () =>
                      ref.read(playbackCoordinatorProvider).toggleActive(),
                ),
                const SizedBox(height: 16),
                Text(
                  isActive ? 'Active — whispers will play' : 'Inactive — all playback paused',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? AppColors.brandLight : AppColors.muted,
                    fontSize: 14,
                  ),
                ),
                const Spacer(flex: 2),
                if (snapshot.state == AppPlaybackState.sleepPaused)
                  _StatusChip(icon: Icons.bedtime, label: 'Sleep mode active'),
                if (snapshot.state == AppPlaybackState.prayerPaused)
                  _StatusChip(icon: Icons.mosque_outlined, label: 'Prayer pause active'),
              ],
            ),
          ),
        ),
        const PlaybackModal(),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.soft)),
        ],
      ),
    );
  }
}

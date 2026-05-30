import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/playback_providers.dart';

class ScheduledOverviewScreen extends ConsumerWidget {
  const ScheduledOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final fmt = DateFormat('MMM d, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Playlists')),
      body: schedulesAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Center(
              child: Text('No schedules yet', style: TextStyle(color: AppColors.muted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = schedules[index];
              return Card(
                child: ListTile(
                  title: Text(s.playlistName),
                  subtitle: Text(
                    'Starts ${fmt.format(s.startTime)} · every ${s.intervalLabel} · ${s.shuffleEnabled ? 'Shuffled' : 'Ordered'}',
                  ),
                  leading: const Icon(Icons.schedule, color: AppColors.gold),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

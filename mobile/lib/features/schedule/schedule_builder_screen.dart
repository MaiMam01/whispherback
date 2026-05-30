import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';

class ScheduleBuilderScreen extends ConsumerStatefulWidget {
  const ScheduleBuilderScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<ScheduleBuilderScreen> createState() => _ScheduleBuilderScreenState();
}

class _ScheduleBuilderScreenState extends ConsumerState<ScheduleBuilderScreen> {
  TimeOfDay _startTime = TimeOfDay.now();
  int _intervalMinutes = 30;
  bool _shuffle = false;

  Future<void> _save() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );

    try {
      await ref.read(scheduleRepositoryProvider).save(
            playlistId: widget.playlistId,
            startTime: start,
            intervalMinutes: _intervalMinutes,
            shuffleEnabled: _shuffle,
          );
      ref.invalidate(schedulesProvider);
      ref.invalidate(playlistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved')),
        );
        context.pop();
      }
    } on ScheduleConflictException catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Schedule conflict'),
          content: Text(
            'This overlaps with "${e.existingPlaylistName}". Adjust the start time or interval.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Playlist')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start time'),
            subtitle: Text(_startTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _startTime);
              if (picked != null) setState(() => _startTime = picked);
            },
          ),
          const Divider(),
          const Text('Interval between clips'),
          Slider(
            value: _intervalMinutes.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            label: '$_intervalMinutes min',
            onChanged: (v) => setState(() => _intervalMinutes = v.round()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shuffle clips'),
            value: _shuffle,
            onChanged: (v) => setState(() => _shuffle = v),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save Schedule')),
        ],
      ),
    );
  }
}

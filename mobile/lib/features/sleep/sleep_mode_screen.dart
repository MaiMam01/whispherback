import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';

class SleepModeScreen extends ConsumerStatefulWidget {
  const SleepModeScreen({super.key});

  @override
  ConsumerState<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends ConsumerState<SleepModeScreen> {
  int _durationMinutes = 60;

  Future<void> _startSleep() async {
    final now = DateTime.now();
    final end = now.add(Duration(minutes: _durationMinutes));
    await ref.read(sleepRepositoryProvider).create(
          startTime: now,
          endTime: end,
        );
    ref.invalidate(activeSleepProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sleep mode until ${DateFormat.Hm().format(end)}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepAsync = ref.watch(activeSleepProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pause all playback for a set period. Sleep mode has the highest priority.',
              style: TextStyle(color: AppColors.muted),
            ),
            sleepAsync.when(
              data: (window) {
                if (window != null && window.active) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.bedtime, color: AppColors.gold),
                        title: const Text('Sleep active'),
                        subtitle: Text(
                          'Until ${DateFormat.Hm().format(window.endTime)}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref.read(sleepRepositoryProvider).deactivateAll();
                            ref.invalidate(activeSleepProvider);
                            setState(() {});
                          },
                          child: const Text('End'),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text('Duration: $_durationMinutes minutes'),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 15,
              max: 480,
              divisions: 31,
              label: '$_durationMinutes min',
              onChanged: (v) => setState(() => _durationMinutes = v.round()),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _startSleep,
              icon: const Icon(Icons.bedtime),
              label: const Text('Start Sleep Mode'),
            ),
          ],
        ),
      ),
    );
  }
}

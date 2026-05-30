import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/prayer_repository.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';

class PrayerSettingsScreen extends ConsumerWidget {
  const PrayerSettingsScreen({super.key});

  static const _methods = ['Karachi', 'MWL', 'ISNA', 'Umm al-Qura', 'Egyptian'];
  static const _madhabs = ['Shafi', 'Hanafi'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(prayerSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Mode')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Prayer times are calculated on your device using GPS. Coordinates are never sent to any server.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: settings.calculationMethod,
              decoration: const InputDecoration(labelText: 'Calculation method'),
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                await ref.read(prayerRepositoryProvider).saveSettings(
                      PrayerSettings(
                        calculationMethod: v,
                        madhab: settings.madhab,
                        useGps: settings.useGps,
                        manualCity: settings.manualCity,
                      ),
                    );
                ref.invalidate(prayerSettingsProvider);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: settings.madhab,
              decoration: const InputDecoration(labelText: 'Asr madhab'),
              items: _madhabs.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                await ref.read(prayerRepositoryProvider).saveSettings(
                      PrayerSettings(
                        calculationMethod: settings.calculationMethod,
                        madhab: v,
                        useGps: settings.useGps,
                        manualCity: settings.manualCity,
                      ),
                    );
                ref.invalidate(prayerSettingsProvider);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use GPS location'),
              subtitle: const Text('Recommended for accurate prayer times'),
              value: settings.useGps,
              onChanged: (v) async {
                await ref.read(prayerRepositoryProvider).saveSettings(
                      PrayerSettings(
                        calculationMethod: settings.calculationMethod,
                        madhab: settings.madhab,
                        useGps: v,
                        manualCity: settings.manualCity,
                      ),
                    );
                ref.invalidate(prayerSettingsProvider);
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

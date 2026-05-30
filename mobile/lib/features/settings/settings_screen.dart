import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showLabels = ref.watch(showLabelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Show labels'),
            subtitle: const Text('Display text under navigation icons'),
            value: showLabels,
            onChanged: (v) => ref.read(showLabelsProvider.notifier).toggle(v),
          ),
          ListTile(
            leading: const Icon(Icons.mosque_outlined, color: AppColors.brandLight),
            title: const Text('Prayer mode settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/prayer'),
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full, color: AppColors.gold),
            title: const Text('Battery optimization guide'),
            subtitle: const Text('Samsung, Xiaomi, Huawei whitelist steps'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Keep WhisperBack running'),
                content: const Text(
                  'On some Android phones, go to Settings → Apps → WhisperBack → Battery → Unrestricted. '
                  'This ensures scheduled clips play on time.',
                ),
                actions: [
                  FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
                ],
              ),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('About'),
            subtitle: Text('WhisperBack v1.0.0 · Local MVP'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'iOS scheduling may drift ±1–2 minutes due to Apple platform limits.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

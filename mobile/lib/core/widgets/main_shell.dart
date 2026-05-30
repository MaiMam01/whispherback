import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/playlists')) return 1;
    if (location.startsWith('/clips')) return 2;
    if (location.startsWith('/schedule')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    final showLabels = whisperTheme(context).showLabels;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/playlists');
            case 2:
              context.go('/clips');
            case 3:
              context.go('/schedule');
            case 4:
              context.go('/settings');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.power_settings_new_outlined),
            selectedIcon: const Icon(Icons.power_settings_new),
            label: showLabels ? 'Home' : '',
            tooltip: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.queue_music_outlined),
            selectedIcon: const Icon(Icons.queue_music),
            label: showLabels ? 'Playlists' : '',
            tooltip: 'Playlists',
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            selectedIcon: const Icon(Icons.library_music),
            label: showLabels ? 'Clips' : '',
            tooltip: 'Clips',
          ),
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            selectedIcon: const Icon(Icons.schedule),
            label: showLabels ? 'Schedule' : '',
            tooltip: 'Schedule',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: showLabels ? 'Settings' : '',
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

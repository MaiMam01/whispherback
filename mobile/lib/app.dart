import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

class WhisperBackApp extends ConsumerWidget {
  const WhisperBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final showLabels = ref.watch(showLabelsProvider);

    return MaterialApp.router(
      title: 'WhisperBack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(showLabels: showLabels),
      routerConfig: router,
    );
  }
}

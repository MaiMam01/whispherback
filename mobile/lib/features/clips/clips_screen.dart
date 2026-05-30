import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/audio_clip.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';

class ClipsScreen extends ConsumerWidget {
  const ClipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipsAsync = ref.watch(clipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clip Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => context.push('/clips/record'),
            tooltip: 'Record',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => context.push('/clips/import'),
            tooltip: 'Import',
          ),
        ],
      ),
      body: clipsAsync.when(
        data: (clips) {
          if (clips.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No clips yet', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/clips/record'),
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final clip = clips[index] as AudioClip;
              return Card(
                child: ListTile(
                  leading: Icon(
                    clip.source == ClipSource.recorded ? Icons.mic : Icons.audio_file,
                    color: AppColors.brandLight,
                  ),
                  title: Text(clip.title),
                  subtitle: Text('${clip.durationLabel} · ${clip.source.name}'),
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

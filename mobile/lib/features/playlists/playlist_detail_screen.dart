import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/playback_providers.dart';
import '../../providers/repository_providers.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  List<dynamic> _clips = [];
  bool _shuffle = false;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(playlistRepositoryProvider);
    final playlist = await repo.getById(widget.playlistId);
    final clips = await repo.getClips(widget.playlistId);
    if (!mounted) return;
    setState(() {
      _name = playlist?.name ?? '';
      _shuffle = playlist?.shuffleEnabled ?? false;
      _clips = clips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          IconButton(
            tooltip: 'Shuffle',
            onPressed: () async {
              await ref.read(playlistRepositoryProvider).setShuffle(widget.playlistId, !_shuffle);
              setState(() => _shuffle = !_shuffle);
            },
            icon: Icon(
              Icons.shuffle,
              color: _shuffle ? AppColors.gold : AppColors.muted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () => context.push('/schedule/build/${widget.playlistId}'),
          ),
        ],
      ),
      body: _clips.isEmpty
          ? const Center(child: Text('No clips yet', style: TextStyle(color: AppColors.muted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clips.length,
              itemBuilder: (context, i) {
                final clip = _clips[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.audiotrack, color: AppColors.brandLight),
                    title: Text(clip.title),
                    subtitle: Text(clip.durationLabel),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _clips.isEmpty
            ? null
            : () => ref.read(playbackCoordinatorProvider).playPlaylist(widget.playlistId),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play'),
      ),
    );
  }
}

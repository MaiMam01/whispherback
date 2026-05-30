import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/playback_providers.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  final _titleController = TextEditingController(text: 'New recording');
  bool _recording = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final service = ref.read(audioRecordingServiceProvider);
    if (_recording) {
      final clip = await service.stopAndSave();
      ref.invalidate(clipsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clip != null ? 'Saved ${clip.title}' : 'Recording cancelled')),
        );
        context.pop();
      }
    } else {
      await service.startRecording(_titleController.text.trim());
      setState(() => _recording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              enabled: !_recording,
              decoration: const InputDecoration(labelText: 'Clip title'),
            ),
            const Spacer(),
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Icon(
                Icons.graphic_eq,
                size: 64,
                color: _recording ? AppColors.gold : AppColors.muted,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _recording ? AppColors.error : AppColors.brand,
                minimumSize: const Size(double.infinity, 52),
              ),
              onPressed: _toggleRecord,
              icon: Icon(_recording ? Icons.stop : Icons.mic),
              label: Text(_recording ? 'Stop & Save' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/playback_providers.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  double _progress = 0;
  bool _importing = false;
  String? _status;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _importing = true;
      _progress = 0;
      _status = 'Importing...';
    });

    final path = result.files.single.path!;
    final title = result.files.single.name;

    try {
      await for (final p in ref.read(audioImportServiceProvider).importFile(path, title)) {
        if (mounted) setState(() => _progress = p);
      }
      ref.invalidate(clipsProvider);
      if (mounted) {
        setState(() => _status = 'Import complete');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clip imported successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Import failed');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Audio')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import MP3 or M4A files from your device. Files are copied into the app for safe playback.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            if (_importing) ...[
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 8),
              Text(
                _status ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.soft),
              ),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _importing ? null : _pickAndImport,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/audio/whisper_audio_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

/// Warns when background audio failed to bind — schedules may not work reliably.
class AudioServiceWarningBanner extends StatelessWidget {
  const AudioServiceWarningBanner({super.key});

  static bool get shouldShow =>
      (Platform.isAndroid || Platform.isIOS) && !whisperAudioServiceBound;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = whisperTheme(context);

    return Material(
      color: AppColors.error.withValues(alpha: theme.isDark ? 0.18 : 0.1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.alertCircle,
                size: 20, color: AppColors.error.withValues(alpha: 0.9)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.audioServiceUnavailableTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: theme.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.audioServiceUnavailableBanner,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: theme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen explanation when Active cannot start without audio service.
Future<void> showAudioServiceUnavailableDialog(BuildContext context) async {
  final l10n = context.l10n;
  final theme = whisperTheme(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.isDark ? AppColors.deep2 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(color: theme.glassBorder),
      ),
      title: Text(l10n.audioServiceUnavailableTitle),
      content: Text(
        l10n.audioServiceUnavailableBody,
        style: TextStyle(color: theme.muted, height: 1.45),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}

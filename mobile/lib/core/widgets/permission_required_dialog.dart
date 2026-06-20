import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

/// Professional permission-denied dialog with Settings guidance.
Future<bool> showPermissionRequiredDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String settingsPath,
  required String openSettingsLabel,
  required String notNowLabel,
}) async {
  final theme = whisperTheme(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.isDark ? AppColors.deep2 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: theme.glassBorder),
      ),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          color: AppColors.gold.withValues(alpha: 0.12),
        ),
        child: const Icon(AppIcons.shield, color: AppColors.gold, size: 24),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: theme.foreground,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: TextStyle(
                color: theme.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.isDark ? theme.glass : AppColors.lightBg2,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: theme.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.settings, size: 16, color: theme.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      settingsPath,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.foreground,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(notNowLabel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(AppIcons.settings, size: 18),
          label: Text(openSettingsLabel),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark({required bool showLabels}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand,
        secondary: AppColors.gold,
        surface: AppColors.card,
        onPrimary: Colors.white,
        onSecondary: AppColors.deep,
        onSurface: AppColors.soft,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deep,
        foregroundColor: AppColors.soft,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.brand.withValues(alpha: 0.3)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deep,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardElevated,
        contentTextStyle: const TextStyle(color: AppColors.soft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      extensions: [
        WhisperThemeExtension(showLabels: showLabels),
      ],
    );
  }
}

class WhisperThemeExtension extends ThemeExtension<WhisperThemeExtension> {
  const WhisperThemeExtension({required this.showLabels});

  final bool showLabels;

  @override
  WhisperThemeExtension copyWith({bool? showLabels}) {
    return WhisperThemeExtension(showLabels: showLabels ?? this.showLabels);
  }

  @override
  WhisperThemeExtension lerp(
    ThemeExtension<WhisperThemeExtension>? other,
    double t,
  ) {
    if (other is! WhisperThemeExtension) return this;
    return WhisperThemeExtension(showLabels: other.showLabels);
  }
}

WhisperThemeExtension whisperTheme(BuildContext context) {
  return Theme.of(context).extension<WhisperThemeExtension>() ??
      const WhisperThemeExtension(showLabels: false);
}

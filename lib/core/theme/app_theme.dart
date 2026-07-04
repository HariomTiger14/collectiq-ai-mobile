import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seedColor = AppColors.accent;

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceMuted,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.secondaryAccent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE6FFFB),
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.violet,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF3E8FF),
      onTertiaryContainer: AppColors.ink,
      error: Color(0xFFB42318),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE4E2),
      onErrorContainer: Color(0xFF7A271A),
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.surface,
      onSurfaceVariant: AppColors.mutedInk,
      outline: Color(0xFFD1D5DB),
      outlineVariant: AppColors.border,
      shadow: Color(0xFF0F172A),
      scrim: Colors.black,
      inverseSurface: AppColors.ink,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFFBFDBFE),
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.h1.copyWith(color: colorScheme.onSurface),
        headlineMedium: AppTextStyles.h1.copyWith(
          color: colorScheme.onSurface,
          fontSize: 30,
        ),
        headlineSmall: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
        displaySmall: AppTextStyles.h1.copyWith(
          color: colorScheme.onSurface,
          fontSize: 30,
        ),
        titleLarge: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
        titleMedium: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
        titleSmall: AppTextStyles.h3.copyWith(
          color: colorScheme.onSurface,
          fontSize: 14,
        ),
        bodyLarge: AppTextStyles.body.copyWith(color: colorScheme.onSurface),
        bodyMedium: AppTextStyles.body.copyWith(
          color: colorScheme.onSurface,
          fontSize: 14,
        ),
        bodySmall: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurface,
        ),
        labelSmall: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppIconSizes.md,
        opticalSize: 24,
        weight: 500,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: const Color(0xFFEFF6FF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}

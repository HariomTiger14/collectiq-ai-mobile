import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.estimatedValueGold,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFEF3C7),
      onTertiaryContainer: Color(0xFF78350F),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.card,
      onSurfaceVariant: AppColors.textSecondary,
      outline: Color(0xFFCBD5E1),
      outlineVariant: AppColors.border,
      shadow: AppColors.shadow,
      scrim: AppColors.overlay,
      inverseSurface: AppColors.secondary,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryLight,
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF34D399),
      onPrimary: Color(0xFF052E2B),
      primaryContainer: Color(0xFF064E3B),
      onPrimaryContainer: Color(0xFFD1FAE5),
      secondary: Color(0xFFE2E8F0),
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: Color(0xFFE2E8F0),
      tertiary: Color(0xFFFBBF24),
      onTertiary: Color(0xFF422006),
      tertiaryContainer: Color(0xFF78350F),
      onTertiaryContainer: Color(0xFFFEF3C7),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF020617),
      onSurface: Color(0xFFE5E7EB),
      surfaceContainerHighest: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF1E293B),
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Color(0xFFE5E7EB),
      onInverseSurface: Color(0xFF020617),
      inversePrimary: AppColors.primaryDark,
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.title.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest
            : AppColors.secondary,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        titleTextStyle: AppTextStyles.title.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.caption.copyWith(color: colorScheme.onSurface),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return TextTheme(
      displaySmall: AppTextStyles.display.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineMedium: AppTextStyles.headline.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineSmall: AppTextStyles.title.copyWith(
        color: colorScheme.onSurface,
        fontSize: 22,
      ),
      titleLarge: AppTextStyles.title.copyWith(color: colorScheme.onSurface),
      titleMedium: AppTextStyles.subtitle.copyWith(
        color: colorScheme.onSurface,
      ),
      titleSmall: AppTextStyles.caption.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: AppTextStyles.body.copyWith(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      bodyMedium: AppTextStyles.body.copyWith(color: colorScheme.onSurface),
      bodySmall: AppTextStyles.caption.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: AppTextStyles.button.copyWith(color: colorScheme.onSurface),
      labelMedium: AppTextStyles.caption.copyWith(color: colorScheme.onSurface),
      labelSmall: AppTextStyles.caption.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }
}

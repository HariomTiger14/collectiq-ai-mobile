import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
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
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: PackLoxTokens.blue,
          onPrimary: PackLoxTokens.textPrimary,
          primaryContainer: PackLoxTokens.surfaceRaised,
          onPrimaryContainer: PackLoxTokens.textPrimary,
          secondary: PackLoxTokens.cyan,
          onSecondary: PackLoxTokens.background,
          secondaryContainer: PackLoxTokens.surfaceRaised,
          onSecondaryContainer: PackLoxTokens.textPrimary,
          tertiary: PackLoxTokens.amber,
          onTertiary: PackLoxTokens.background,
          tertiaryContainer: PackLoxTokens.surfaceRaised,
          onTertiaryContainer: PackLoxTokens.textPrimary,
          error: PackLoxTokens.error,
          onError: PackLoxTokens.textPrimary,
          errorContainer: PackLoxTokens.error.withValues(alpha: 0.20),
          onErrorContainer: PackLoxTokens.textPrimary,
          surface: PackLoxTokens.background,
          surfaceContainerLow: PackLoxTokens.surface,
          surfaceContainer: PackLoxTokens.surface,
          surfaceContainerHigh: PackLoxTokens.surfaceRaised,
          surfaceContainerHighest: PackLoxTokens.surfaceRaised,
          onSurface: PackLoxTokens.textPrimary,
          onSurfaceVariant: PackLoxTokens.textSecondary,
          outline: PackLoxTokens.border,
          outlineVariant: PackLoxTokens.border,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: PackLoxTokens.textPrimary,
          onInverseSurface: PackLoxTokens.background,
          inversePrimary: const Color(0xFF93C5FD),
        );

    return _baseTheme(colorScheme);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final raisedSurface = colorScheme.surfaceContainerHighest;
    final elevatedSurface = isDark
        ? PackLoxTokens.surfaceRaised
        : colorScheme.surfaceContainerHighest;
    final overlaySurface = isDark
        ? PackLoxTokens.surfaceRaised
        : colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      canvasColor: colorScheme.surface,
      cardColor: raisedSurface,
      dividerColor: colorScheme.outlineVariant,
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
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: raisedSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.36 : 0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: overlaySurface,
        modalBackgroundColor: overlaySurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.42 : 0.16),
        modalBarrierColor: colorScheme.scrim.withValues(
          alpha: isDark ? 0.58 : 0.34,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: overlaySurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.40 : 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
        contentTextStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: raisedSurface,
        indicatorColor: isDark
            ? PackLoxTokens.blue.withValues(alpha: 0.28)
            : const Color(0xFFEFF6FF),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? PackLoxTokens.surface : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevatedSurface,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}

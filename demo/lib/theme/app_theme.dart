import 'package:demo/theme/app_colors.dart';
import 'package:demo/theme/app_radius.dart';
import 'package:demo/theme/app_typography.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.surfaceAlt,
        secondary: AppColors.accentCyan,
        secondaryContainer: AppColors.surface,
        tertiary: AppColors.accentMint,
        tertiaryContainer: AppColors.surfaceAlt,
        appBarColor: AppColors.background,
        error: AppColors.error,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 18,
      scaffoldBackground: AppColors.background,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.field,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.field,
          borderSide: const BorderSide(color: Color(0x334A6FBF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.field,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get light {
    final base = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: Color(0xFFDCE8FF),
        secondary: AppColors.accentCyan,
        secondaryContainer: Color(0xFFDCF8FF),
        tertiary: AppColors.accentMint,
        tertiaryContainer: Color(0xFFDDF9EF),
        appBarColor: Colors.white,
        error: AppColors.error,
      ),
      useMaterial3: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      swapLegacyOnMaterial3: true,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

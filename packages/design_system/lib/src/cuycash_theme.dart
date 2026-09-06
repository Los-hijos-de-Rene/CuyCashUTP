import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Tema de CuyCash construido SOLO desde tokens (DESIGN.md).
abstract final class CuyCashTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: CuyCashColors.primary,
      onPrimary: CuyCashColors.onPrimary,
      secondary: CuyCashColors.secondary,
      surface: CuyCashColors.surface,
      onSurface: CuyCashColors.onSurface,
      error: CuyCashColors.error,
      onError: CuyCashColors.onError,
      outline: CuyCashColors.outline,
      outlineVariant: CuyCashColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CuyCashColors.surface,
      dividerColor: CuyCashColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: CuyCashColors.surface,
        foregroundColor: CuyCashColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: CuyCashTypography.titleMd,
      ),
      cardTheme: CardThemeData(
        color: CuyCashColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CuyCashColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.input),
          borderSide: const BorderSide(color: CuyCashColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.input),
          borderSide: const BorderSide(color: CuyCashColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.input),
          borderSide: const BorderSide(color: CuyCashColors.primary, width: 2),
        ),
        hintStyle: CuyCashTypography.bodyLg
            .copyWith(color: CuyCashColors.secondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CuyCashColors.primaryContainer,
          foregroundColor: CuyCashColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: CuyCashTypography.labelMd
              .copyWith(color: CuyCashColors.onPrimary, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CuyCashRadii.button),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: CuyCashTypography.displayLg,
        headlineMedium: CuyCashTypography.headlineMd,
        titleMedium: CuyCashTypography.titleMd,
        bodyLarge: CuyCashTypography.bodyLg,
        bodyMedium: CuyCashTypography.bodyMd,
        labelMedium: CuyCashTypography.labelMd,
      ),
    );
  }
}

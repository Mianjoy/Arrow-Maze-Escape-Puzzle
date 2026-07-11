import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Construye el [ThemeData] global de la app con la paleta minimalista del proyecto.
abstract final class AppTheme {
  /// Crea un tema Material 3 alineado a [AppColors].
  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.arrow,
      brightness: Brightness.light,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      error: AppColors.arrowBlocked,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.arrow,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.arrow,
          side: const BorderSide(color: AppColors.arrow),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.boardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

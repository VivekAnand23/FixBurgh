import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Material 3 themes seeded from the brand navy.
abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.orange700,
      tertiary: AppColors.teal700,
      error: AppColors.danger,
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.dark,
      secondary: AppColors.orange,
      tertiary: AppColors.teal,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    const pill = StadiumBorder();
    const minSize = Size(64, 52);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: pill,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: pill,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}

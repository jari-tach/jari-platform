import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1F6FEB);
  static const Color primaryDark = Color(0xFF144DA8);
  static const Color accent = Color(0xFF00A86B);
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAF1FF);
  static const Color textPrimary = Color(0xFF10233F);
  static const Color textSecondary = Color(0xFF61708A);
  static const Color border = Color(0xFFDDE4F0);
  static const Color warning = Color(0xFFFFA726);
}

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get headlineLarge => GoogleFonts.tajawal(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.tajawal(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodyMedium => GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

class AppButtonStyles {
  const AppButtonStyles._();

  static ButtonStyle get primary => ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
    ),
  );

  static ButtonStyle get secondary => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border, width: 1.2),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
    ),
  );
}

class AppCardStyles {
  const AppCardStyles._();

  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    side: const BorderSide(color: AppColors.border, width: 1),
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.tajawalTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: AppCardStyles.cardShape,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primary,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.secondary,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.tajawalTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
    );

    return base;
  }
}

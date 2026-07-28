import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'saeq_semantic_colors.dart';

/// App theme configuration
///
/// Complete design system including:
/// - Typography
/// - Spacing
/// - Radius
/// - Elevation
/// - Shadows
/// - Colors (light and dark)
/// - Semantic [SaeqSemanticColors] extension (Design System Sprint 1)
/// - Theme helpers
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Typography
  static const String fontFamily = 'Tajawal'; // Arabic-friendly font
  static const String fontFamilyFallback = 'Roboto';

  // Font sizes
  static const double fontSizeXS = 12.0;
  static const double fontSizeSM = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeLG = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;

  // Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Spacing (4 / 8 / 12 / 16 / 20 / 24 / 32)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacing12 = 12.0;
  static const double spacingMD = 16.0;
  static const double spacing20 = 20.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  /// Minimum interactive touch target (Material / a11y).
  static const double minTouchTarget = 48.0;

  // Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 9999.0;

  // Elevation
  static const double elevationXS = 1.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;
  static const double elevationXL = 16.0;

  // Border width
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 2.0;
  static const double borderWidthThick = 3.0;

  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: const Color(0xFF1B5E20), // Green 900
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF4CAF50), // Green 500
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF2E7D32), // Green 800
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF81C784), // Green 300
      onSecondaryContainer: Colors.black,
      tertiary: const Color(0xFF00ACC1), // Cyan 600
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF4DD0E1), // Cyan 200
      onTertiaryContainer: Colors.black,
      error: const Color(0xFFD32F2F), // Red 700
      onError: Colors.white,
      errorContainer: const Color(0xFFFFCDD2), // Red 100
      onErrorContainer: const Color(0xFFB71C1C), // Red 900
      surface: Colors.white,
      onSurface: const Color(0xFF212121), // Grey 900
      surfaceContainerHighest: const Color(0xFFF5F5F5), // Grey 100
      onSurfaceVariant: const Color(0xFF757575), // Grey 600
      outline: const Color(0xFFE0E0E0), // Grey 300
      outlineVariant: const Color(0xFFBDBDBD), // Grey 400
      shadow: Colors.black.withValues(alpha: 0.1),
      scrim: Colors.black.withValues(alpha: 0.5),
      inverseSurface: const Color(0xFF212121),
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFF81C784),
      surfaceTint: const Color(0xFF1B5E20),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: SaeqSemanticColors.light.background,
      extensions: const <ThemeExtension<dynamic>>[SaeqSemanticColors.light],

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: elevationSM,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: colorScheme.onPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevationSM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        color: colorScheme.surface,
        shadowColor: colorScheme.shadow,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: elevationSM,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.tajawal(
            fontSize: fontSizeMD,
            fontWeight: fontWeightSemiBold,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outline,
            width: borderWidthMedium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.tajawal(
            fontSize: fontSizeMD,
            fontWeight: fontWeightSemiBold,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMD,
            vertical: spacingSM,
          ),
          textStyle: GoogleFonts.tajawal(
            fontSize: fontSizeSM,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: borderWidthMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: borderWidthMedium,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: borderWidthMedium,
          ),
        ),
        contentPadding: const EdgeInsets.all(spacingMD),
        labelStyle: GoogleFonts.tajawal(
          fontSize: fontSizeSM,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.tajawal(
          fontSize: fontSizeSM,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: borderWidthThin,
        space: spacingSM,
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24.0),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.tajawal(
          fontSize: fontSizeXXXL,
          fontWeight: fontWeightBold,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.tajawal(
          fontSize: fontSizeXXL,
          fontWeight: fontWeightBold,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.tajawal(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.tajawal(
          fontSize: fontSizeXXL,
          fontWeight: fontWeightSemiBold,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemiBold,
          color: colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.tajawal(
          fontSize: fontSizeLG,
          fontWeight: fontWeightSemiBold,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: fontSizeLG,
          fontWeight: fontWeightMedium,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: fontSizeMD,
          fontWeight: fontWeightMedium,
          color: colorScheme.onSurface,
        ),
        titleSmall: GoogleFonts.tajawal(
          fontSize: fontSizeSM,
          fontWeight: fontWeightMedium,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: fontSizeMD,
          fontWeight: fontWeightRegular,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: fontSizeSM,
          fontWeight: fontWeightRegular,
          color: colorScheme.onSurface,
        ),
        bodySmall: GoogleFonts.tajawal(
          fontSize: fontSizeXS,
          fontWeight: fontWeightRegular,
          color: colorScheme.onSurface,
        ),
        labelLarge: GoogleFonts.tajawal(
          fontSize: fontSizeSM,
          fontWeight: fontWeightMedium,
          color: colorScheme.onSurface,
        ),
        labelMedium: GoogleFonts.tajawal(
          fontSize: fontSizeXS,
          fontWeight: fontWeightMedium,
          color: colorScheme.onSurface,
        ),
        labelSmall: GoogleFonts.tajawal(
          fontSize: fontSizeXS,
          fontWeight: fontWeightRegular,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFF81C784), // Green 300
      onPrimary: const Color(0xFF1B5E20), // Green 900
      primaryContainer: const Color(0xFF2E7D32), // Green 800
      onPrimaryContainer: const Color(0xFF81C784), // Green 300
      secondary: const Color(0xFF4CAF50), // Green 500
      onSecondary: const Color(0xFF1B5E20), // Green 900
      secondaryContainer: const Color(0xFF1B5E20), // Green 900
      onSecondaryContainer: const Color(0xFF81C784), // Green 300
      tertiary: const Color(0xFF4DD0E1), // Cyan 200
      onTertiary: const Color(0xFF006064), // Cyan 900
      tertiaryContainer: const Color(0xFF00ACC1), // Cyan 600
      onTertiaryContainer: const Color(0xFF4DD0E1), // Cyan 200
      error: const Color(0xFFEF5350), // Red 400
      onError: const Color(0xFFB71C1C), // Red 900
      errorContainer: const Color(0xFFB71C1C), // Red 900
      onErrorContainer: const Color(0xFFFFCDD2), // Red 100
      surface: const Color(0xFF121212), // Material dark surface
      onSurface: const Color(0xFFE0E0E0), // Grey 300
      surfaceContainerHighest: const Color(0xFF1E1E1E), // Grey 900
      onSurfaceVariant: const Color(0xFFBDBDBD), // Grey 400
      outline: const Color(0xFF424242), // Grey 800
      outlineVariant: const Color(0xFF616161), // Grey 700
      shadow: Colors.black.withValues(alpha: 0.3),
      scrim: Colors.black.withValues(alpha: 0.7),
      inverseSurface: const Color(0xFFE0E0E0),
      onInverseSurface: const Color(0xFF212121),
      inversePrimary: const Color(0xFF1B5E20),
      surfaceTint: const Color(0xFF81C784),
    );

    return lightTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SaeqSemanticColors.dark.background,
      extensions: const <ThemeExtension<dynamic>>[SaeqSemanticColors.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: elevationSM,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: elevationSM,
        color: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// App colors for direct usage.
///
/// Prefer [SaeqSemanticColors.of] in new widgets. These aliases keep Sprint 1
/// compatible with existing Inc1/Inc2 call sites and map to the temporary
/// Forest Green light palette.
class AppColors {
  AppColors._();

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color elevatedSurface = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFF7F8F7);
  static const Color border = Color(0xFFE0E0E0);
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryContainer = Color(0xFFE8F5E9);
  static const Color secondary = Color(0xFF2E7D32);
  static const Color accent = Color(0xFF00838F);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color disabled = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color information = Color(0xFF0277BD);
  static const Color busy = Color(0xFFEF6C00);
}

/// App text styles for direct usage (Arabic-first metrics).
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle supporting = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle monetary = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle deliveryCode = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle status = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}

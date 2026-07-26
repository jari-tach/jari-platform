import 'package:flutter/material.dart';

/// Semantic SAEQ Driver color tokens (Design System Sprint 1).
///
/// Temporary recommended palette: **Forest Green** (Arabic-first, high contrast).
/// Replace by swapping [SaeqSemanticColors.light] / [.dark] only — do not scatter hex
/// in feature widgets.
///
/// Candidate palettes considered (not implemented):
/// 1. Forest Green (selected temporary)
/// 2. Deep Teal professional
/// 3. Midnight navy + amber accent
@immutable
class SaeqSemanticColors extends ThemeExtension<SaeqSemanticColors> {
  const SaeqSemanticColors({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.disabled,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.information,
    required this.informationContainer,
    required this.overlay,
    required this.scrim,
    required this.busy,
    required this.busyContainer,
  });

  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color disabled;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color information;
  final Color informationContainer;
  final Color overlay;
  final Color scrim;
  final Color busy;
  final Color busyContainer;

  /// Temporary brand palette A — Forest Green (Sprint 1 default).
  static const SaeqSemanticColors light = SaeqSemanticColors(
    primary: Color(0xFF1B5E20),
    primaryContainer: Color(0xFFE8F5E9),
    secondary: Color(0xFF2E7D32),
    accent: Color(0xFF00838F),
    background: Color(0xFFF7F8F7),
    surface: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFF5F5F5),
    border: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF616161),
    disabled: Color(0xFF9E9E9E),
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFE8F5E9),
    warning: Color(0xFFE65100),
    warningContainer: Color(0xFFFFF3E0),
    error: Color(0xFFD32F2F),
    errorContainer: Color(0xFFFFEBEE),
    information: Color(0xFF0277BD),
    informationContainer: Color(0xFFE1F5FE),
    overlay: Color(0x1A000000),
    scrim: Color(0x80000000),
    busy: Color(0xFFEF6C00),
    busyContainer: Color(0xFFFFF3E0),
  );

  static const SaeqSemanticColors dark = SaeqSemanticColors(
    primary: Color(0xFF81C784),
    primaryContainer: Color(0xFF1B5E20),
    secondary: Color(0xFFA5D6A7),
    accent: Color(0xFF4DD0E1),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    elevatedSurface: Color(0xFF2A2A2A),
    border: Color(0xFF424242),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFBDBDBD),
    disabled: Color(0xFF757575),
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1B5E20),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF4E342E),
    error: Color(0xFFEF5350),
    errorContainer: Color(0xFFB71C1C),
    information: Color(0xFF4FC3F7),
    informationContainer: Color(0xFF01579B),
    overlay: Color(0x33FFFFFF),
    scrim: Color(0xB3000000),
    busy: Color(0xFFFFB74D),
    busyContainer: Color(0xFF4E342E),
  );

  static SaeqSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<SaeqSemanticColors>() ?? light;
  }

  @override
  SaeqSemanticColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? disabled,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? information,
    Color? informationContainer,
    Color? overlay,
    Color? scrim,
    Color? busy,
    Color? busyContainer,
  }) {
    return SaeqSemanticColors(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      disabled: disabled ?? this.disabled,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      information: information ?? this.information,
      informationContainer: informationContainer ?? this.informationContainer,
      overlay: overlay ?? this.overlay,
      scrim: scrim ?? this.scrim,
      busy: busy ?? this.busy,
      busyContainer: busyContainer ?? this.busyContainer,
    );
  }

  @override
  SaeqSemanticColors lerp(ThemeExtension<SaeqSemanticColors>? other, double t) {
    if (other is! SaeqSemanticColors) return this;
    return SaeqSemanticColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      information: Color.lerp(information, other.information, t)!,
      informationContainer: Color.lerp(
        informationContainer,
        other.informationContainer,
        t,
      )!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      busy: Color.lerp(busy, other.busy, t)!,
      busyContainer: Color.lerp(busyContainer, other.busyContainer, t)!,
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Compact status chip (availability, delivery stage, document status).
class SaeqStatusChip extends StatelessWidget {
  const SaeqStatusChip({
    super.key,
    required this.label,
    this.tone = SaeqStatusTone.neutral,
    this.icon,
  });

  final String label;
  final SaeqStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(tone);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ({Color background, Color border, Color foreground}) _colorsFor(
    SaeqStatusTone tone,
  ) {
    return switch (tone) {
      SaeqStatusTone.success => (
        background: const Color(0xFFE8F5E9),
        border: AppColors.primary.withValues(alpha: 0.35),
        foreground: AppColors.primary,
      ),
      SaeqStatusTone.warning => (
        background: const Color(0xFFFFF8E1),
        border: const Color(0xFFFFB300),
        foreground: const Color(0xFFF57C00),
      ),
      SaeqStatusTone.danger => (
        background: const Color(0xFFFFEBEE),
        border: AppColors.error.withValues(alpha: 0.4),
        foreground: AppColors.error,
      ),
      SaeqStatusTone.neutral => (
        background: AppColors.surfaceVariant,
        border: AppColors.border,
        foreground: AppColors.secondary,
      ),
    };
  }
}

enum SaeqStatusTone { neutral, success, warning, danger }

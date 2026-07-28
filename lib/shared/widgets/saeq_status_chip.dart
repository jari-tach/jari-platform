import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Compact status chip (availability, delivery stage, document status).
///
/// Uses icon + text + container tone — never color alone for meaning.
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
    final colors = _colorsFor(context, tone);
    final resolvedIcon = icon ?? _defaultIcon(tone);
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
            Icon(resolvedIcon, size: 14, color: colors.foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.status.copyWith(color: colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _defaultIcon(SaeqStatusTone tone) {
    return switch (tone) {
      SaeqStatusTone.success => Icons.check_circle_outline,
      SaeqStatusTone.warning => Icons.warning_amber_outlined,
      SaeqStatusTone.danger => Icons.error_outline,
      SaeqStatusTone.neutral => Icons.info_outline,
      SaeqStatusTone.busy => Icons.hourglass_top_outlined,
    };
  }

  static ({Color background, Color border, Color foreground}) _colorsFor(
    BuildContext context,
    SaeqStatusTone tone,
  ) {
    final t = SaeqSemanticColors.of(context);
    return switch (tone) {
      SaeqStatusTone.success => (
        background: t.successContainer,
        border: t.success.withValues(alpha: 0.35),
        foreground: t.success,
      ),
      SaeqStatusTone.warning => (
        background: t.warningContainer,
        border: t.warning.withValues(alpha: 0.45),
        foreground: t.warning,
      ),
      SaeqStatusTone.danger => (
        background: t.errorContainer,
        border: t.error.withValues(alpha: 0.4),
        foreground: t.error,
      ),
      SaeqStatusTone.busy => (
        background: t.busyContainer,
        border: t.busy.withValues(alpha: 0.45),
        foreground: t.busy,
      ),
      SaeqStatusTone.neutral => (
        background: t.elevatedSurface,
        border: t.border,
        foreground: t.textSecondary,
      ),
    };
  }
}

enum SaeqStatusTone { neutral, success, warning, danger, busy }

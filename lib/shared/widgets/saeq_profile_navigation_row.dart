import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Profile menu row — 56dp, rounded 12, bordered, chevron navigation.
class SaeqProfileNavigationRow extends StatelessWidget {
  const SaeqProfileNavigationRow({
    super.key,
    required this.label,
    this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final enabled = onTap != null;
    final labelColor = destructive
        ? colors.error
        : (enabled ? colors.textPrimary : colors.disabled);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

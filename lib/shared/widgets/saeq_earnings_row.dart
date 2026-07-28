import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Earnings list row with strong monetary typography.
class SaeqEarningsRow extends StatelessWidget {
  const SaeqEarningsRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Text(
            amountLabel,
            style: AppTextStyles.monetary.copyWith(color: colors.primary),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

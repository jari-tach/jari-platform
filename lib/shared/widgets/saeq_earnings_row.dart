import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Earnings list row.
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
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Text(amountLabel, style: AppTextStyles.titleMedium),
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

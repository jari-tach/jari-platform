import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class SaeqSectionCard extends StatelessWidget {
  const SaeqSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.child,
  });

  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.bodyMedium),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

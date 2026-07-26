import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Generic content card with optional title/subtitle.
class SaeqInfoCard extends StatelessWidget {
  const SaeqInfoCard({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.onTap,
    this.leading,
    this.trailing,
  });

  final String? title;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || leading != null || trailing != null)
            Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppTheme.spacingSM),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!, style: AppTextStyles.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(subtitle!, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          if (child != null) ...[
            if (title != null || subtitle != null)
              const SizedBox(height: AppTheme.spacingMD),
            child!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

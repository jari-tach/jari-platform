import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'saeq_secondary_button.dart';

/// Shared empty-state body (icon + title + message + optional action).
class SaeqEmptyState extends StatelessWidget {
  const SaeqEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  static const emptyKey = Key('saeqEmptyState');
  static const actionKey = Key('saeqEmptyStateAction');

  @override
  Widget build(BuildContext context) {
    return Center(
      key: emptyKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.secondary,
            semanticLabel: title,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AppTheme.spacingLG),
            SaeqSecondaryButton(
              key: actionKey,
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

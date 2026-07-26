import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'saeq_primary_button.dart';

/// Shared error-state body with retry.
class SaeqErrorState extends StatelessWidget {
  const SaeqErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.semanticsLabel,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? semanticsLabel;

  static const errorKey = Key('saeqErrorState');
  static const retryKey = Key('saeqErrorStateRetry');

  @override
  Widget build(BuildContext context) {
    return Center(
      key: errorKey,
      child: Semantics(
        liveRegion: true,
        label: semanticsLabel ?? title,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppTheme.spacingMD),
            Text(title, style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: retryKey,
              label: retryLabel,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

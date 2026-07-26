import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
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
    final colors = SaeqSemanticColors.of(context);

    return Center(
      key: errorKey,
      child: Semantics(
        liveRegion: true,
        label: semanticsLabel ?? title,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              title,
              style: AppTextStyles.headlineLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.error),
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

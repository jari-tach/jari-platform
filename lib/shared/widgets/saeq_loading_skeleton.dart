import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Centered loading body with optional title/message.
class SaeqLoadingSkeleton extends StatelessWidget {
  const SaeqLoadingSkeleton({
    super.key,
    this.title,
    this.message,
    this.semanticsLabel,
  });

  final String? title;
  final String? message;
  final String? semanticsLabel;

  static const progressKey = Key('saeqLoadingSkeleton');

  @override
  Widget build(BuildContext context) {
    return Center(
      key: progressKey,
      child: Semantics(
        label: semanticsLabel ?? title,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (title != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Text(title!, style: AppTextStyles.titleMedium),
            ],
            if (message != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                message!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Driver identity header with optional avatar placeholder.
class SaeqProfileHeader extends StatelessWidget {
  const SaeqProfileHeader({
    super.key,
    required this.fullName,
    required this.maskedPhone,
    this.email,
    this.showAvatar = true,
  });

  final String fullName;
  final String maskedPhone;
  final String? email;
  final bool showAvatar;

  static const headerKey = Key('saeqProfileHeader');

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);

    return Semantics(
      key: headerKey,
      header: true,
      label: '$fullName, $maskedPhone',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            Semantics(
              label: fullName,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: colors.primaryContainer,
                child: Icon(Icons.person_outline, color: colors.primary),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  maskedPhone,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    email!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

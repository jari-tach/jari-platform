import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Compact offline indicator for Home / shell surfaces.
class SaeqOfflineBanner extends StatelessWidget {
  const SaeqOfflineBanner({
    super.key,
    required this.message,
    this.visible = true,
  });

  final String message;
  final bool visible;

  static const bannerKey = Key('saeqOfflineBanner');

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final colors = SaeqSemanticColors.of(context);

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        key: bannerKey,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: colors.warning.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: colors.warning),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Color(0xFFE65100)),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFE65100),
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

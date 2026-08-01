import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../domain/entities/realtime_connection_status.dart';

/// Quiet realtime connection banner — no Snackbars, no modal noise.
class RealtimeConnectionBanner extends StatelessWidget {
  const RealtimeConnectionBanner({
    super.key,
    required this.status,
    required this.message,
  });

  final RealtimeConnectionStatus status;
  final String message;

  static const bannerKey = Key('saeqRealtimeConnectionBanner');

  bool get _visible => switch (status) {
    RealtimeConnectionStatus.reconnecting ||
    RealtimeConnectionStatus.degraded ||
    RealtimeConnectionStatus.catchingUp => true,
    _ => false,
  };

  IconData get _icon => switch (status) {
    RealtimeConnectionStatus.degraded => Icons.cloud_off_outlined,
    RealtimeConnectionStatus.catchingUp => Icons.sync,
    _ => Icons.wifi_protected_setup,
  };

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

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
          color: colors.informationContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: colors.information.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(_icon, color: colors.information),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.information,
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

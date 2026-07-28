import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import 'saeq_status_chip.dart';

/// Notification list row — title, body, read/unread chip (icon + text).
class SaeqNotificationRow extends StatelessWidget {
  const SaeqNotificationRow({
    super.key,
    required this.title,
    required this.body,
    required this.isRead,
    required this.readLabel,
    required this.unreadLabel,
    this.onTap,
  });

  final String title;
  final String body;
  final bool isRead;
  final String readLabel;
  final String unreadLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: isRead
            ? colors.surface
            : colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isRead
              ? colors.border
              : colors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          SaeqStatusChip(
            label: isRead ? readLabel : unreadLabel,
            tone: isRead ? SaeqStatusTone.neutral : SaeqStatusTone.warning,
            icon: isRead
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
          ),
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

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Full-width tappable settings row showing the current value.
class SaeqSettingsRow extends StatelessWidget {
  const SaeqSettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.selected = false,
    this.icon,
    this.showChevron = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border.withValues(alpha: 0.65)),
            ),
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.35)
                : null,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colors.textSecondary, size: 20),
                const SizedBox(width: AppTheme.spacingSM),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: enabled ? colors.textPrimary : colors.disabled,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppTheme.spacingSM),
                Flexible(
                  child: Text(
                    value!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected ? colors.primary : colors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (selected && value == null)
                Icon(Icons.check_circle, color: colors.primary, size: 20),
              if (showChevron) ...[
                const SizedBox(width: AppTheme.spacingXS),
                Icon(
                  Icons.chevron_right,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

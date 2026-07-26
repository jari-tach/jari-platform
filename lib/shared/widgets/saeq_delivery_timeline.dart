import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Horizontal-ish stage progress for active delivery.
///
/// Completed / current / upcoming are distinguished by icon + weight + color
/// (not color alone). Temporary Forest Green palette via [SaeqSemanticColors].
class SaeqDeliveryTimeline extends StatelessWidget {
  const SaeqDeliveryTimeline({
    super.key,
    required this.labels,
    required this.activeIndex,
  });

  final List<String> labels;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final colors = SaeqSemanticColors.of(context);
    final index = activeIndex.clamp(0, labels.length - 1);
    return Semantics(
      container: true,
      label: labels[index],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Row(
              children: [
                Icon(
                  i < index
                      ? Icons.check_circle
                      : i == index
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: i < index
                      ? colors.success
                      : i == index
                      ? colors.primary
                      : colors.disabled,
                  size: 22,
                  semanticLabel: i < index
                      ? 'completed'
                      : i == index
                      ? 'current'
                      : 'upcoming',
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    labels[i],
                    style: i == index
                        ? AppTextStyles.titleMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          )
                        : AppTextStyles.bodyMedium.copyWith(
                            color: i < index
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                  ),
                ),
              ],
            ),
            if (i < labels.length - 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 10,
                  top: 2,
                  bottom: 2,
                ),
                child: Container(
                  width: 2,
                  height: 14,
                  color: i < index ? colors.success : colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

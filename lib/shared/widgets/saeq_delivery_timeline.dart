import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Horizontal-ish stage progress for active delivery.
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
    final index = activeIndex.clamp(0, labels.length - 1);
    return Column(
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
                color: i <= index ? AppColors.primary : AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  labels[i],
                  style: i == index
                      ? AppTextStyles.titleMedium
                      : AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          if (i < labels.length - 1)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 9,
                top: 2,
                bottom: 2,
              ),
              child: Container(width: 2, height: 12, color: AppColors.border),
            ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Single filter chip with semantic selected / unselected tones.
class SaeqFilterChip extends StatelessWidget {
  const SaeqFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final background = selected
        ? colors.primaryContainer
        : colors.elevatedSurface;
    final border = selected ? colors.primary : colors.border;
    final foreground = selected ? colors.primary : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: border),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal filter bar — wraps chips with consistent spacing (RTL-safe).
class SaeqFilterChipBar extends StatelessWidget {
  const SaeqFilterChipBar({super.key, required this.chips});

  final List<SaeqFilterChip> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingSM,
      children: chips,
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Compact icon button with 48 logical-pixel minimum touch target.
class SaeqIconButton extends StatelessWidget {
  const SaeqIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return SizedBox(
      width: AppTheme.minTouchTarget,
      height: AppTheme.minTouchTarget,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, semanticLabel: semanticLabel ?? tooltip),
        color: colors.textPrimary,
        disabledColor: colors.disabled,
      ),
    );
  }
}

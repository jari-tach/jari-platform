import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Primary CTA with optional loading / disabled (48dp min height).
class SaeqPrimaryButton extends StatelessWidget {
  const SaeqPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : icon == null
        ? Text(label, textAlign: TextAlign.center, style: AppTextStyles.button)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button,
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size(0, AppTheme.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
        child: child,
      ),
    );
  }
}

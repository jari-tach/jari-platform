import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Dominant full-width delivery workflow action (stage primary CTA).
class SaeqDeliveryActionButton extends StatelessWidget {
  const SaeqDeliveryActionButton({
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
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : icon == null
        ? Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.button.copyWith(fontSize: 17),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(fontSize: 17),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colors.primary.withValues(alpha: 0.45),
            disabledForegroundColor: Colors.white70,
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

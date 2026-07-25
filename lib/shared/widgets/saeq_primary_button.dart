import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SaeqPrimaryButton extends StatelessWidget {
  const SaeqPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label, textAlign: TextAlign.center)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: child,
      ),
    );
  }
}

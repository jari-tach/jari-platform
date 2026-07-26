import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'saeq_destructive_button.dart';
import 'saeq_secondary_button.dart';

/// Destructive confirm dialog (sign-out, delete, etc.).
class SaeqDestructiveDialog extends StatelessWidget {
  const SaeqDestructiveDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => SaeqDestructiveDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: AppTextStyles.titleLarge),
      content: Text(message, style: AppTextStyles.bodyMedium),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SaeqDestructiveButton(
              key: const Key('saeqDestructiveDialogConfirm'),
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqSecondaryButton(
              key: const Key('saeqDestructiveDialogCancel'),
              label: cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}

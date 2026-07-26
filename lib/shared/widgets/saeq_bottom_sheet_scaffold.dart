import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// RTL-safe modal bottom sheet scaffold.
class SaeqBottomSheetScaffold extends StatelessWidget {
  const SaeqBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? subtitle,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (context) => SaeqBottomSheetScaffold(
        title: title,
        subtitle: subtitle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMD,
        right: AppTheme.spacingMD,
        top: AppTheme.spacingMD,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingMD,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(title, style: AppTextStyles.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(subtitle!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppTheme.spacingMD),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

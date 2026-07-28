import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_primary_button.dart';

/// Figma `Final/Auth/First Launch` (node 40:4).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final isArabic = l10n.isArabic;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.firstLaunchTitle,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: colors.textPrimary,
                  fontSize: AppTheme.fontSizeXXL,
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                l10n.firstLaunchSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  fontSize: AppTheme.fontSizeSM,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              SaeqPrimaryButton(
                label: l10n.firstLaunchStartAction,
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                height: AppTheme.minTouchTarget,
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(appLocaleProvider.notifier)
                        .setLocale(
                          isArabic ? const Locale('en') : const Locale('ar'),
                        );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    textStyle: AppTextStyles.button.copyWith(
                      fontWeight: AppTheme.fontWeightBold,
                      fontSize: AppTheme.fontSizeMD,
                    ),
                  ),
                  child: Text(
                    isArabic
                        ? l10n.firstLaunchSwitchToEnglish
                        : l10n.firstLaunchSwitchToArabic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

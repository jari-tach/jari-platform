import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_brand_mark.dart';
import '../../../shared/widgets/saeq_primary_button.dart';

/// Figma `Final/Auth/First Launch` + Brand / فزعة Lockup.
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
              const SaeqBrandLockup(
                markSize: 64,
                showTagline: true,
                alignment: CrossAxisAlignment.start,
              ),
              const SizedBox(height: AppTheme.spacingLG),
              SaeqPrimaryButton(
                key: const Key('welcomeStart'),
                label: l10n.firstLaunchStartAction,
                onPressed: () => context.go(AppRoutes.onboarding),
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                height: AppTheme.minTouchTarget,
                width: double.infinity,
                child: TextButton(
                  key: const Key('welcomeLocaleToggle'),
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
              if (kDebugMode) ...[
                SizedBox(
                  height: AppTheme.minTouchTarget,
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('welcomeThemeToggle'),
                    onPressed: () {
                      final isDark =
                          ref.read(appThemeModeProvider) == ThemeMode.dark;
                      ref
                          .read(appThemeModeProvider.notifier)
                          .setThemeMode(
                            isDark ? ThemeMode.light : ThemeMode.dark,
                          );
                    },
                    style: TextButton.styleFrom(foregroundColor: colors.primary),
                    child: Text(
                      ref.watch(appThemeModeProvider) == ThemeMode.dark
                          ? l10n.settingsThemeLight
                          : l10n.settingsThemeDark,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.minTouchTarget,
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('welcomeSessionExpiredDemo'),
                    onPressed: () => context.go(AppRoutes.sessionExpired),
                    child: Text(l10n.simulateSessionExpiredAction),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

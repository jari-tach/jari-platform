import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';

/// Figma `DRV-AUTH-002-Onboarding` — Continue / Skip → Login.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final isArabic = l10n.isArabic;
    final themeMode = ref.watch(appThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const Key('onboardingBack'),
                  onPressed: () => context.go(AppRoutes.welcome),
                  child: Text(l10n.backAction),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                key: const Key('onboardingTitle'),
                l10n.onboardingTitle,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: colors.textPrimary,
                  fontSize: AppTheme.fontSizeXXL,
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                l10n.onboardingSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  fontSize: AppTheme.fontSizeSM,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: i == 0 ? colors.primary : colors.border,
                    ),
                  );
                }),
              ),
              const Spacer(flex: 3),
              SaeqPrimaryButton(
                key: const Key('onboardingContinue'),
                label: l10n.onboardingContinueAction,
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                height: AppTheme.minTouchTarget,
                child: TextButton(
                  key: const Key('onboardingSkip'),
                  onPressed: () => context.go(AppRoutes.login),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                  child: Text(l10n.onboardingSkipAction),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const Key('onboardingLocaleToggle'),
                      onPressed: () {
                        ref
                            .read(appLocaleProvider.notifier)
                            .setLocale(
                              isArabic
                                  ? const Locale('en')
                                  : const Locale('ar'),
                            );
                      },
                      child: Text(
                        isArabic
                            ? l10n.firstLaunchSwitchToEnglish
                            : l10n.firstLaunchSwitchToArabic,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      key: const Key('onboardingThemeToggle'),
                      onPressed: () {
                        ref
                            .read(appThemeModeProvider.notifier)
                            .setThemeMode(
                              isDark ? ThemeMode.light : ThemeMode.dark,
                            );
                      },
                      child: Text(
                        isDark
                            ? l10n.settingsThemeLight
                            : l10n.settingsThemeDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

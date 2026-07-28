import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_destructive_button.dart';
import '../../../../shared/widgets/saeq_destructive_dialog.dart';
import '../../../../shared/widgets/saeq_info_card.dart';
import '../../../../shared/widgets/saeq_settings_row.dart';
import '../../../../shared/widgets/saeq_settings_section.dart';
import '../../../auth/domain/entities/auth_error.dart';
import '../../../auth/presentation/controllers/auth_controller_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../availability/presentation/providers/availability_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const signOutKey = Key('settingsSignOut');

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }

  static String _languageLabel(AppLocalizations l10n, Locale locale) {
    return locale.languageCode == 'ar'
        ? l10n.settingsLanguageArabic
        : l10n.settingsLanguageEnglish;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          children: [
            SaeqSettingsSection(
              title: l10n.settingsAppearanceSectionTitle,
              subtitle: l10n.settingsAppearanceSectionSubtitle,
              children: [
                SaeqSettingsRow(
                  label: l10n.settingsThemeSystem,
                  key: themeMode == ThemeMode.system
                      ? const Key('settingsThemeValue')
                      : null,
                  value: themeMode == ThemeMode.system
                      ? _themeLabel(l10n, themeMode)
                      : null,
                  selected: themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
                SaeqSettingsRow(
                  label: l10n.settingsThemeLight,
                  key: themeMode == ThemeMode.light
                      ? const Key('settingsThemeValue')
                      : null,
                  value: themeMode == ThemeMode.light
                      ? _themeLabel(l10n, themeMode)
                      : null,
                  selected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                SaeqSettingsRow(
                  label: l10n.settingsThemeDark,
                  key: themeMode == ThemeMode.dark
                      ? const Key('settingsThemeValue')
                      : null,
                  value: themeMode == ThemeMode.dark
                      ? _themeLabel(l10n, themeMode)
                      : null,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SaeqSettingsSection(
              title: l10n.settingsLanguageSectionTitle,
              subtitle: l10n.settingsLanguageSectionSubtitle,
              children: [
                SaeqSettingsRow(
                  label: l10n.settingsLanguageArabic,
                  key: locale.languageCode == 'ar'
                      ? const Key('settingsLanguageValue')
                      : null,
                  value: locale.languageCode == 'ar'
                      ? _languageLabel(l10n, locale)
                      : null,
                  selected: locale.languageCode == 'ar',
                  onTap: () => ref
                      .read(appLocaleProvider.notifier)
                      .setLocale(const Locale('ar')),
                ),
                SaeqSettingsRow(
                  label: l10n.settingsLanguageEnglish,
                  key: locale.languageCode == 'en'
                      ? const Key('settingsLanguageValue')
                      : null,
                  value: locale.languageCode == 'en'
                      ? _languageLabel(l10n, locale)
                      : null,
                  selected: locale.languageCode == 'en',
                  onTap: () => ref
                      .read(appLocaleProvider.notifier)
                      .setLocale(const Locale('en')),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SaeqInfoCard(
              title: l10n.settingsAboutSectionTitle,
              subtitle: l10n.settingsAboutSectionSubtitle,
              child: Text(
                l10n.settingsAppVersionLabel(AppConfig.appVersion),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SaeqSettingsSection(
              title: l10n.settingsAccountSectionTitle,
              subtitle: l10n.settingsAccountSectionSubtitle,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  child: SaeqDestructiveButton(
                    key: signOutKey,
                    label: l10n.signOut,
                    icon: Icons.logout,
                    onPressed: () => _confirmSignOut(context, ref, l10n),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await SaeqDestructiveDialog.show(
      context,
      title: l10n.signOutConfirmTitle,
      message: l10n.signOutConfirmMessage,
      confirmLabel: l10n.signOut,
      cancelLabel: l10n.cancelAction,
    );
    if (confirmed == true) {
      // Best-effort availability cleanup before auth session clear.
      // Auth signOut still proceeds if availability prep fails (e.g. active delivery).
      await ref
          .read(availabilityControllerProvider.notifier)
          .prepareForLogout();
      await ref.read(authControllerProvider.notifier).signOut();
      if (!context.mounted) return;
      final authState = ref.read(authControllerProvider);
      if (authState.status == AuthControllerStatus.failure &&
          authState.error is SecureStorageFailureError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.secureStorageFailureMessage)),
        );
      }
    }
  }
}

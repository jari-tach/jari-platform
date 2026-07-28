import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../providers/auth_providers.dart';

/// Figma `DRV-AUTH-006-SessionExpired` — Login Again → `/login`.
class SessionExpiredScreen extends ConsumerWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);

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
                  key: const Key('sessionExpiredBack'),
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(l10n.backAction),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                key: const Key('sessionExpiredTitle'),
                l10n.sessionExpiredTitle,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: colors.textPrimary,
                  fontSize: AppTheme.fontSizeXXL,
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                l10n.sessionExpiredMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  fontSize: AppTheme.fontSizeSM,
                ),
              ),
              const Spacer(flex: 3),
              SaeqPrimaryButton(
                key: const Key('sessionExpiredLoginAgain'),
                label: l10n.sessionExpiredLoginAgain,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).clearError();
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

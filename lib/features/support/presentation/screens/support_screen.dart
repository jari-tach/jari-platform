import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_info_card.dart';
import '../../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../../shared/widgets/saeq_secondary_button.dart';
import '../../domain/entities/support_config.dart';
import '../providers/support_providers.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final configAsync = ref.watch(supportConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportScreenTitle)),
      body: SafeArea(
        child: configAsync.when(
          loading: () => SaeqLoadingSkeleton(title: l10n.loading),
          error: (error, stackTrace) => SaeqEmptyState(
            title: l10n.supportContactUnavailableTitle,
            message: l10n.supportContactUnavailableMessage,
            icon: Icons.support_agent_outlined,
          ),
          data: (config) => ListView(
            padding: const EdgeInsets.all(AppConstants.contentPadding),
            children: [
              SaeqInfoCard(
                title: l10n.supportAboutSectionTitle,
                subtitle: l10n.settingsAboutSectionSubtitle,
                child: Text(
                  l10n.settingsAppVersionLabel(AppConfig.appVersion),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              SaeqInfoCard(
                title: l10n.supportFaqSectionTitle,
                child: Column(
                  children: [
                    _FaqTile(
                      question: l10n.supportFaq1Question,
                      answer: l10n.supportFaq1Answer,
                    ),
                    _FaqTile(
                      question: l10n.supportFaq2Question,
                      answer: l10n.supportFaq2Answer,
                    ),
                    _FaqTile(
                      question: l10n.supportFaq3Question,
                      answer: l10n.supportFaq3Answer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              SaeqInfoCard(
                title: l10n.supportContactSectionTitle,
                child: _ContactSection(config: config, l10n: l10n),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              SaeqSecondaryButton(
                label: l10n.supportSafetyTipsAction,
                icon: Icons.health_and_safety_outlined,
                onPressed: () => context.push(AppRoutes.supportSafety),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          collapsedShape: const RoundedRectangleBorder(),
          shape: const RoundedRectangleBorder(),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            question,
            style: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
                child: Text(
                  answer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.config, required this.l10n});

  final SupportConfig config;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (!config.hasAnyContact) {
      return SaeqEmptyState(
        title: l10n.supportContactUnavailableTitle,
        message: l10n.supportContactUnavailableMessage,
        icon: Icons.contact_support_outlined,
      );
    }

    final colors = SaeqSemanticColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (config.hasPhone)
          _ContactRow(
            icon: Icons.phone_outlined,
            label: l10n.supportContactPhoneLabel,
            value: config.phone!,
            colors: colors,
          ),
        if (config.hasEmail) ...[
          if (config.hasPhone) const SizedBox(height: AppTheme.spacingSM),
          _ContactRow(
            icon: Icons.email_outlined,
            label: l10n.supportContactEmailLabel,
            value: config.email!,
            colors: colors,
          ),
        ],
        if (config.hasHelpUrl) ...[
          if (config.hasPhone || config.hasEmail)
            const SizedBox(height: AppTheme.spacingSM),
          _ContactRow(
            icon: Icons.link_outlined,
            label: l10n.supportContactHelpUrlLabel,
            value: config.helpUrl!,
            colors: colors,
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String value;
  final SaeqSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.textSecondary, size: 20),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

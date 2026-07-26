import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/saeq_primary_button.dart';
import '../../../shared/widgets/saeq_section_card.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        AppConstants.appName.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.appName,
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.appTagline,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.welcomeTitle,
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                localizations.welcomeSubtitle,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 24),
              SaeqPrimaryButton(
                label: localizations.exploreArchitecture,
                icon: Icons.auto_awesome,
                onPressed: () => context.push(AppRoutes.comingSoon),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // `go` (not `push`): login is an entry point, not a
                  // sub-screen of Welcome. Keeps the back stack clean after
                  // a successful sign-in redirects to /home.
                  onPressed: () => context.go(AppRoutes.login),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: Text(localizations.signIn),
                ),
              ),
              const SizedBox(height: 24),
              SaeqSectionCard(
                title: localizations.architectureTitle,
                subtitle: localizations.architectureSubtitle,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Chip(label: localizations.readyForGrowth),
                    _Chip(label: localizations.sharedDesignSystem),
                    _Chip(label: localizations.servicesLayer),
                    _Chip(label: localizations.apiReady),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SaeqSectionCard(
                title: localizations.nextStepsTitle,
                subtitle: localizations.nextStepsSubtitle,
                child: Text(localizations.nextStepsFocusMessage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_info_card.dart';

/// Safety tips for drivers — informational only (no auto-dial).
class SupportSafetyScreen extends StatelessWidget {
  const SupportSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportSafetyScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          children: [
            SaeqInfoCard(
              title: l10n.supportSafetyScreenTitle,
              subtitle: l10n.supportSafetyIntro,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tip(text: l10n.supportSafetyTip1, colors: colors),
                  const SizedBox(height: AppTheme.spacingSM),
                  _Tip(text: l10n.supportSafetyTip2, colors: colors),
                  const SizedBox(height: AppTheme.spacingSM),
                  _Tip(text: l10n.supportSafetyTip3, colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text, required this.colors});

  final String text;
  final SaeqSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: colors.success, size: 20),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

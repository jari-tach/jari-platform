import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_info_card.dart';
import '../batch_feature.dart';

/// Natural fake fixture entry on the offers surface — no developer controls.
class BatchOfferEntryCard extends StatelessWidget {
  const BatchOfferEntryCard({super.key});

  static const cardKey = Key('batchOfferEntryCard');
  static const openKey = Key('batchOfferEntryOpen');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final batchId = FakeBatchService.defaultBatchId;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SaeqInfoCard(
      key: cardKey,
      title: l10n.batchEntryTitle,
      subtitle: l10n.batchEntryMessage(4),
      leading: Icon(Icons.layers_outlined, color: colors.primary),
      trailing: Icon(
        isRtl ? Icons.chevron_left : Icons.chevron_right,
        color: colors.textSecondary,
      ),
      onTap: () => context.push(AppRoutes.batchOfferPath(batchId)),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: openKey,
          onPressed: () => context.push(AppRoutes.batchOfferPath(batchId)),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.batchEntryAction),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            minimumSize: const Size(0, AppTheme.minTouchTarget),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_empty_state.dart';
import '../../../shared/widgets/saeq_error_state.dart';
import '../../../shared/widgets/saeq_info_card.dart';
import '../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../shared/widgets/saeq_primary_button.dart';
import '../../../shared/widgets/saeq_status_chip.dart';
import 'documents_feature.dart';
import 'documents_ui_helpers.dart';

class DocumentsListScreen extends ConsumerWidget {
  const DocumentsListScreen({super.key});

  static const uploadKey = Key('documentsUploadAction');
  static const eligibilityBannerKey = Key('documentsEligibilityBanner');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(documentsListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.documentsTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            children: [
              Expanded(child: _body(context, ref, l10n, state)),
              SaeqPrimaryButton(
                key: uploadKey,
                label: l10n.documentsUploadAction,
                icon: Icons.upload_file_outlined,
                onPressed: () => context.push(AppRoutes.profileDocumentsUpload),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DocumentsListState state,
  ) {
    switch (state.status) {
      case DocumentsViewStatus.loading:
        return SaeqLoadingSkeleton(
          title: l10n.documentsLoadingTitle,
          message: l10n.documentsLoadingMessage,
        );
      case DocumentsViewStatus.empty:
        return SaeqEmptyState(
          title: l10n.documentsEmptyTitle,
          message: l10n.documentsEmptyMessage,
          icon: Icons.description_outlined,
        );
      case DocumentsViewStatus.offline:
        return SaeqErrorState(
          title: l10n.documentsOfflineTitle,
          message: l10n.documentsOfflineMessage,
          retryLabel: l10n.profileRetry,
          onRetry: ref.read(documentsListControllerProvider.notifier).load,
        );
      case DocumentsViewStatus.error:
        return SaeqErrorState(
          title: l10n.documentsErrorTitle,
          message: l10n.documentsErrorMessage,
          retryLabel: l10n.profileRetry,
          onRetry: ref.read(documentsListControllerProvider.notifier).load,
        );
      case DocumentsViewStatus.loaded:
        final showBanner = documentsHaveEligibilityWarnings(state.documents);
        return ListView(
          children: [
            if (showBanner) ...[
              _EligibilityBanner(l10n: l10n),
              const SizedBox(height: AppTheme.spacingMD),
            ],
            ...state.documents.map((document) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
                child: SaeqInfoCard(
                  key: Key('documentRow-${document.id}'),
                  title: documentTypeLabel(l10n, document.type),
                  subtitle:
                      '${document.maskedNumber}\n${documentCardDateSubtitle(l10n, document)}',
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SaeqStatusChip(
                      label: documentStatusLabel(l10n, document.status),
                      tone: documentStatusTone(document.status),
                    ),
                  ),
                  onTap: () => context.push(
                    AppRoutes.profileDocumentDetail(document.id),
                  ),
                ),
              );
            }),
          ],
        );
    }
  }
}

class _EligibilityBanner extends StatelessWidget {
  const _EligibilityBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final theme = Theme.of(context);
    return Semantics(
      key: DocumentsListScreen.eligibilityBannerKey,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.documentsEligibilityBannerTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              l10n.documentsEligibilityBannerMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncDocument = ref.watch(documentDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.documentDetailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: asyncDocument.when(
            loading: () => SaeqLoadingSkeleton(title: l10n.loading),
            error: (_, _) => SaeqErrorState(
              title: l10n.documentsErrorTitle,
              message: l10n.documentsErrorMessage,
              retryLabel: l10n.profileRetry,
              onRetry: () => ref.invalidate(documentDetailProvider(id)),
            ),
            data: (document) {
              if (document == null) {
                return SaeqEmptyState(
                  title: l10n.documentsEmptyTitle,
                  message: l10n.documentsEmptyMessage,
                  icon: Icons.description_outlined,
                );
              }
              final locale = l10n.locale.languageCode;
              final dateFormat = DateFormat.yMMMd(locale);
              return ListView(
                children: [
                  SaeqInfoCard(
                    title: documentTypeLabel(l10n, document.type),
                    trailing: SaeqStatusChip(
                      label: documentStatusLabel(l10n, document.status),
                      tone: documentStatusTone(document.status),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: l10n.documentNumberLabel,
                          value: document.maskedNumber,
                        ),
                        if (document.issueDate != null)
                          _DetailRow(
                            label: l10n.documentIssueDateLabel,
                            value: dateFormat.format(document.issueDate!),
                          ),
                        _DetailRow(
                          label: l10n.documentExpiryLabel,
                          value: dateFormat.format(document.expiryDate),
                        ),
                        if (document.uploadedAt != null)
                          _DetailRow(
                            label: l10n.documentUploadedDateLabel,
                            value: dateFormat.format(document.uploadedAt!),
                          ),
                        if (document.rejectionReasonCode != null)
                          _DetailRow(
                            label: l10n.documentRejectionReasonLabel,
                            value: documentRejectionReasonLabel(
                              l10n,
                              document.rejectionReasonCode!,
                            ),
                          ),
                        _DetailRow(
                          label: l10n.documentEligibilityImpactLabel,
                          value: documentEligibilityImpactLabel(
                            l10n,
                            document.eligibilityImpact,
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          if (value.isNotEmpty) ...[
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

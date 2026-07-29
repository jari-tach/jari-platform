import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_info_card.dart';
import '../../../shared/widgets/saeq_primary_button.dart';
import '../../../shared/widgets/saeq_secondary_button.dart';
import 'documents_feature.dart';
import 'documents_ui_helpers.dart';

class DocumentUploadScreen extends ConsumerWidget {
  const DocumentUploadScreen({super.key});

  static const selectFileKey = Key('documentSelectFakeFile');
  static const uploadKey = Key('documentUploadSubmit');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(documentUploadControllerProvider);
    final controller = ref.read(documentUploadControllerProvider.notifier);
    final isUploading = state.status == DocumentUploadStatus.uploading;

    ref.listen(documentUploadControllerProvider, (previous, next) {
      if (next.status == DocumentUploadStatus.uploadSuccess &&
          previous?.status != DocumentUploadStatus.uploadSuccess) {
        ref.read(documentsListControllerProvider.notifier).load();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.documentUploadSuccess)));
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.documentUploadTitle)),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppConstants.contentPadding,
            AppConstants.contentPadding,
            AppConstants.contentPadding,
            MediaQuery.viewInsetsOf(context).bottom +
                AppConstants.contentPadding,
          ),
          children: [
            Text(
              l10n.documentUploadHint,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<DocumentType>(
              key: ValueKey(state.selectedType),
              isExpanded: true,
              initialValue: state.selectedType,
              decoration: InputDecoration(labelText: l10n.documentTypeLabel),
              items: DocumentType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(documentTypeLabel(l10n, type)),
                    ),
                  )
                  .toList(),
              onChanged: isUploading
                  ? null
                  : (value) {
                      if (value != null) controller.selectType(value);
                    },
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SaeqSecondaryButton(
              key: selectFileKey,
              label: l10n.documentUploadSelectAction,
              icon: Icons.attach_file_outlined,
              onPressed: isUploading ? null : controller.selectFakeFile,
            ),
            if (state.file != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              SaeqInfoCard(
                title: l10n.documentFakeFileLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.file!.name),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${state.file!.sizeLabel} · ${state.file!.mimeType}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (state.status == DocumentUploadStatus.validationError)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMD),
                child: Text(
                  l10n.documentValidationMessage,
                  style: TextStyle(color: colors.error),
                ),
              ),
            if (state.status == DocumentUploadStatus.uploadFailure)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMD),
                child: Text(
                  l10n.documentUploadFailure,
                  style: TextStyle(color: colors.error),
                ),
              ),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: uploadKey,
              label: isUploading
                  ? l10n.documentUploadingAction
                  : l10n.documentUploadSubmitAction,
              isLoading: isUploading,
              onPressed: isUploading ? null : controller.upload,
            ),
          ],
        ),
      ),
    );
  }
}

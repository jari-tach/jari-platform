import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/saeq_status_chip.dart';
import 'documents_feature.dart';

String documentTypeLabel(AppLocalizations l10n, DocumentType type) {
  return switch (type) {
    DocumentType.nationalId => l10n.documentTypeNationalId,
    DocumentType.driverLicense => l10n.documentTypeDriverLicense,
    DocumentType.vehicleRegistration => l10n.documentTypeVehicleRegistration,
    DocumentType.insurance => l10n.documentTypeInsurance,
  };
}

String documentStatusLabel(AppLocalizations l10n, DocumentReviewStatus status) {
  return switch (status) {
    DocumentReviewStatus.approved => l10n.statusApproved,
    DocumentReviewStatus.underReview => l10n.statusUnderReview,
    DocumentReviewStatus.rejected => l10n.statusRejected,
    DocumentReviewStatus.expiringSoon => l10n.statusExpiringSoon,
    DocumentReviewStatus.expired => l10n.statusExpired,
  };
}

SaeqStatusTone documentStatusTone(DocumentReviewStatus status) {
  return switch (status) {
    DocumentReviewStatus.approved => SaeqStatusTone.success,
    DocumentReviewStatus.underReview => SaeqStatusTone.warning,
    DocumentReviewStatus.rejected => SaeqStatusTone.danger,
    DocumentReviewStatus.expiringSoon => SaeqStatusTone.warning,
    DocumentReviewStatus.expired => SaeqStatusTone.danger,
  };
}

String documentEligibilityImpactLabel(
  AppLocalizations l10n,
  DocumentEligibilityImpact impact,
) {
  return switch (impact) {
    DocumentEligibilityImpact.none => l10n.documentImpactNone,
    DocumentEligibilityImpact.blocksAvailability =>
      l10n.documentImpactBlocksAvailability,
    DocumentEligibilityImpact.blocksVehicleApproval =>
      l10n.documentImpactBlocksVehicleApproval,
    DocumentEligibilityImpact.requiresRenewal =>
      l10n.documentImpactRequiresRenewal,
  };
}

String documentRejectionReasonLabel(
  AppLocalizations l10n,
  DocumentRejectionReasonCode code,
) {
  return switch (code) {
    DocumentRejectionReasonCode.plateNumberMismatch =>
      l10n.documentRejectionPlateMismatch,
  };
}

String documentCardDateSubtitle(
  AppLocalizations l10n,
  DocumentViewData document,
) {
  final locale = l10n.locale.languageCode;
  final dateFormat = DateFormat.yMMMd(locale);
  if (document.status == DocumentReviewStatus.underReview &&
      document.uploadedAt != null) {
    return l10n.documentUploadedSubtitle(
      dateFormat.format(document.uploadedAt!),
    );
  }
  return l10n.documentExpirySubtitle(dateFormat.format(document.expiryDate));
}

bool documentsHaveEligibilityWarnings(List<DocumentViewData> documents) {
  return documents.any(
    (document) =>
        document.status == DocumentReviewStatus.rejected ||
        document.status == DocumentReviewStatus.expired ||
        document.status == DocumentReviewStatus.expiringSoon ||
        document.status == DocumentReviewStatus.underReview ||
        document.eligibilityImpact != DocumentEligibilityImpact.none,
  );
}

import '../../../../core/localization/app_localizations.dart';
import '../../domain/failures/delivery_failure.dart';

/// Maps typed [DeliveryFailure] values to localized UI copy.
///
/// Presentation-only — no domain policy, storage, or repository knowledge.
String deliveryFailureMessage(DeliveryFailure failure, AppLocalizations l10n) {
  return switch (failure) {
    DeliveryUnauthenticated() => l10n.deliveryFailureUnauthenticated,
    DeliveryOfflineAcceptDenied() => l10n.deliveryFailureOfflineAccept,
    DeliveryNotAvailable() => l10n.deliveryFailureNotAvailable,
    DeliveryOfferNotFound() => l10n.deliveryFailureOfferNotFound,
    DeliveryOfferExpired() => l10n.deliveryFailureOfferExpired,
    DeliveryOfferTaken() => l10n.deliveryFailureOfferTaken,
    DeliveryConflict() => l10n.deliveryFailureConflict,
    InvalidDeliveryOfferTransition() => l10n.deliveryFailureInvalidTransition,
    DeliveryActiveOfferConflict() => l10n.deliveryFailureActiveOfferConflict,
    DeliveryActiveAssignmentExists() =>
      l10n.deliveryFailureActiveAssignmentExists,
    DeliveryPersistenceFailure() => l10n.deliveryFailurePersistence,
    DeliverySecurityPolicyDenied() => l10n.deliveryFailureSecurityDenied,
    DeliveryAvailabilityBindFailure() => l10n.deliveryFailureAvailabilityBind,
    InvalidDeliveryWorkflowTransition() => l10n.deliveryWorkflowFailureMessage,
    DeliveryVerificationFailed() => l10n.deliveryVerificationFailureMessage,
    DeliveryAssignmentNotFound() => l10n.deliveryFailureOfferNotFound,
    DeliveryInvalidCommandId() => l10n.deliveryFailureSecurityDenied,
    DeliveryPendingSync() => l10n.deliveryPendingSyncMessage,
    DeliveryUnknownFailure() => l10n.deliveryFailureUnknown,
  };
}

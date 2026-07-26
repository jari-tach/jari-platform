import '../entities/delivery_assignment.dart';

/// Typed delivery-domain failures (PHASE 2.5). Safe for logs — no tokens/PII.
sealed class DeliveryFailure implements Exception {
  const DeliveryFailure(this.message);

  /// Human-readable log message (not for direct UI without localization map).
  final String message;

  /// Deterministic machine-readable identity.
  String get code;

  @override
  String toString() => '[$code] $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryFailure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, code, message);
}

/// No authenticated session / expired session.
final class DeliveryUnauthenticated extends DeliveryFailure {
  const DeliveryUnauthenticated([
    super.message = 'Authenticated session required for delivery actions.',
  ]);

  @override
  String get code => 'delivery.unauthenticated';
}

/// Accept attempted without connectivity (ADR-024).
final class DeliveryOfflineAcceptDenied extends DeliveryFailure {
  const DeliveryOfflineAcceptDenied([
    super.message = 'Accept requires connectivity; offline accept is denied.',
  ]);

  @override
  String get code => 'delivery.offline_accept_denied';
}

/// Driver is not confirmed available for accepting work.
final class DeliveryNotAvailable extends DeliveryFailure {
  const DeliveryNotAvailable([
    super.message =
        'Confirmed available status is required before accepting an offer.',
  ]);

  @override
  String get code => 'delivery.not_available';
}

/// Offer is missing or not actionable.
final class DeliveryOfferNotFound extends DeliveryFailure {
  const DeliveryOfferNotFound([
    super.message = 'Delivery offer was not found or is not actionable.',
  ]);

  @override
  String get code => 'delivery.offer_not_found';
}

/// Offer window ended (410-class).
final class DeliveryOfferExpired extends DeliveryFailure {
  const DeliveryOfferExpired([super.message = 'Delivery offer has expired.']);

  @override
  String get code => 'delivery.offer_expired';
}

/// Another driver took the offer (409-class).
final class DeliveryOfferTaken extends DeliveryFailure {
  const DeliveryOfferTaken([
    super.message = 'Delivery offer was taken by another driver.',
  ]);

  @override
  String get code => 'delivery.offer_taken';
}

/// Stale revision / generic conflict.
final class DeliveryConflict extends DeliveryFailure {
  const DeliveryConflict([
    super.message = 'Delivery offer state conflicts with the current revision.',
  ]);

  @override
  String get code => 'delivery.conflict';
}

/// Transition not on the allow-list (ADR-022).
final class InvalidDeliveryOfferTransition extends DeliveryFailure {
  const InvalidDeliveryOfferTransition([
    super.message = 'Delivery offer transition is not allowed.',
  ]);

  @override
  String get code => 'delivery.invalid_transition';
}

/// One-active-offer policy violation (ADR-023).
final class DeliveryActiveOfferConflict extends DeliveryFailure {
  const DeliveryActiveOfferConflict([
    super.message = 'Another active delivery offer already exists.',
  ]);

  @override
  String get code => 'delivery.active_offer_conflict';
}

/// Active assignment already present (MVP one active delivery).
final class DeliveryActiveAssignmentExists extends DeliveryFailure {
  const DeliveryActiveAssignmentExists([
    super.message = 'An active delivery assignment already exists.',
  ]);

  @override
  String get code => 'delivery.active_assignment_exists';
}

/// Local persistence of assignment failed (ADR-028).
final class DeliveryPersistenceFailure extends DeliveryFailure {
  const DeliveryPersistenceFailure([
    super.message = 'Failed to persist the delivery assignment locally.',
  ]);

  @override
  String get code => 'delivery.persistence_failure';
}

/// Security / identity mismatch.
final class DeliverySecurityPolicyDenied extends DeliveryFailure {
  const DeliverySecurityPolicyDenied([
    super.message = 'Delivery action denied by security policy.',
  ]);

  @override
  String get code => 'delivery.security_policy_denied';
}

/// Accept succeeded and assignment was persisted, but availability busy
/// binding failed (ADR-025). Assignment must remain locally preserved.
final class DeliveryAvailabilityBindFailure extends DeliveryFailure {
  const DeliveryAvailabilityBindFailure([
    super.message =
        'Delivery was accepted but availability could not be marked busy.',
    this.assignment,
  ]);

  /// Persisted assignment when accept already succeeded (compensation: keep).
  final DeliveryAssignment? assignment;

  @override
  String get code => 'delivery.availability_bind_failure';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAvailabilityBindFailure &&
          code == other.code &&
          message == other.message &&
          assignment == other.assignment;

  @override
  int get hashCode => Object.hash(runtimeType, code, message, assignment);
}

/// Unexpected domain failure.
final class DeliveryUnknownFailure extends DeliveryFailure {
  const DeliveryUnknownFailure([
    super.message = 'Unexpected delivery failure.',
  ]);

  @override
  String get code => 'delivery.unknown';
}

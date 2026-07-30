import '../entities/accept_delivery_offer_request.dart';
import '../entities/delivery_assignment.dart';
import '../entities/delivery_offer.dart';
import '../entities/delivery_offer_status.dart';
import '../entities/delivery_result.dart';
import '../entities/local_delivery_command.dart';
import '../failures/delivery_failure.dart';
import '../policies/delivery_offer_transition_decision.dart';
import '../policies/delivery_offer_transition_policy.dart';
import '../repositories/delivery_assignment_repository.dart';
import '../repositories/delivery_command_repository.dart';
import '../repositories/delivery_offer_repository.dart';

/// Accepts a delivery offer under default-deny preconditions (ADR-022/024/025).
///
/// Does not mutate availability directly; callers bind busy after success
/// using the returned [DeliveryAssignment.assignmentId] (ADR-025).
class AcceptDeliveryOffer {
  /// Creates the use case.
  const AcceptDeliveryOffer(
    this._offerRepository,
    this._assignmentRepository, {
    this._transitionPolicy = const DeliveryOfferTransitionPolicy(),
    this.commandRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DeliveryOfferRepository _offerRepository;
  final DeliveryAssignmentRepository _assignmentRepository;
  final DeliveryOfferTransitionPolicy _transitionPolicy;
  final DeliveryCommandRepository? commandRepository;
  final DateTime Function() _clock;

  /// Validates preconditions, accepts via repository, then persists locally.
  Future<DeliveryResult<DeliveryAssignment>> call(
    AcceptDeliveryOfferRequest request,
  ) async {
    if (!request.connectivityOnline) {
      return const DeliveryFailureResult(DeliveryOfflineAcceptDenied());
    }

    if (!request.isConfirmedAvailable) {
      return const DeliveryFailureResult(DeliveryNotAvailable());
    }

    if (request.hasActiveAssignment) {
      return const DeliveryFailureResult(DeliveryActiveAssignmentExists());
    }

    final existing = await _assignmentRepository.getActiveAssignment(
      driverId: request.driverId,
    );
    if (existing.isFailure) {
      return DeliveryFailureResult(
        existing.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }
    final active = existing.valueOrNull;
    if (active != null && active.isActive) {
      if (active.offerId == request.offerId &&
          active.completedCommandIds.contains(request.idempotencyKey)) {
        return DeliverySuccess(active);
      }
      return const DeliveryFailureResult(DeliveryActiveAssignmentExists());
    }

    final offersResult = await _offerRepository.getDeliveryOffers(
      driverId: request.driverId,
    );
    final offers = offersResult.valueOrNull;
    if (offers == null) {
      return DeliveryFailureResult(
        offersResult.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    DeliveryOffer? matched;
    for (final offer in offers) {
      if (offer.offerId == request.offerId) {
        matched = offer;
        break;
      }
    }
    if (matched == null) {
      return const DeliveryFailureResult(DeliveryOfferNotFound());
    }
    if (matched.driverId != request.driverId) {
      return const DeliveryFailureResult(DeliverySecurityPolicyDenied());
    }

    final transition = _transitionPolicy.evaluate(
      DeliveryOfferTransitionContext(
        current: matched.status,
        requested: DeliveryOfferStatus.accepting,
      ),
    );
    if (!transition.allowed) {
      return DeliveryFailureResult(
        transition.failure ?? const InvalidDeliveryOfferTransition(),
      );
    }

    final acceptResult = await _offerRepository.acceptOffer(request);
    final assignment = acceptResult.valueOrNull;
    if (assignment == null) {
      return DeliveryFailureResult(
        acceptResult.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    if (assignment.driverId != request.driverId ||
        assignment.offerId != request.offerId) {
      return const DeliveryFailureResult(
        DeliverySecurityPolicyDenied(
          'Accepted assignment identity does not match the request.',
        ),
      );
    }

    final localAssignment = assignment.copyWith(
      completedCommandIds: {
        ...assignment.completedCommandIds,
        request.idempotencyKey,
      },
    );
    final persist = await _assignmentRepository.upsertAccepted(localAssignment);
    if (persist.isFailure) {
      return DeliveryFailureResult(
        persist.failureOrNull ?? const DeliveryPersistenceFailure(),
      );
    }

    // The assignment itself already persists the command id. This durable
    // ledger additionally prevents the consumed Fake offer from reappearing
    // after the completed assignment is cleared.
    await commandRepository?.save(
      LocalDeliveryCommand(
        commandId: request.idempotencyKey,
        driverId: request.driverId,
        targetId: request.offerId,
        type: LocalDeliveryCommandType.acceptOffer,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
      ),
    );

    return DeliverySuccess(localAssignment);
  }
}

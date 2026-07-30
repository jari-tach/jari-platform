import '../entities/delivery_offer.dart';
import '../entities/delivery_offer_status.dart';
import '../entities/delivery_result.dart';
import '../entities/local_delivery_command.dart';
import '../entities/reject_delivery_offer_request.dart';
import '../failures/delivery_failure.dart';
import '../policies/delivery_offer_transition_decision.dart';
import '../policies/delivery_offer_transition_policy.dart';
import '../repositories/delivery_offer_repository.dart';
import '../repositories/delivery_command_repository.dart';

/// Rejects a delivery offer without creating an assignment (ADR-021 / ADR-024).
class RejectDeliveryOffer {
  /// Creates the use case.
  const RejectDeliveryOffer(
    this._offerRepository, {
    this._transitionPolicy = const DeliveryOfferTransitionPolicy(),
    this.commandRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DeliveryOfferRepository _offerRepository;
  final DeliveryOfferTransitionPolicy _transitionPolicy;
  final DeliveryCommandRepository? commandRepository;
  final DateTime Function() _clock;

  /// Validates transition preconditions then rejects via the repository.
  Future<DeliveryResult<void>> call(RejectDeliveryOfferRequest request) async {
    final commandId = request.idempotencyKey?.trim();
    if (request.idempotencyKey != null && commandId!.isEmpty) {
      return const DeliveryFailureResult(DeliveryInvalidCommandId());
    }
    if (commandId != null && commandRepository != null) {
      final existing = await commandRepository!.getById(commandId: commandId);
      if (existing.isFailure) {
        return DeliveryFailureResult(
          existing.failureOrNull ?? const DeliveryPersistenceFailure(),
        );
      }
      final recorded = existing.valueOrNull;
      if (recorded != null) {
        if (!recorded.matches(
          driverId: request.driverId,
          targetId: request.offerId,
          type: LocalDeliveryCommandType.rejectOffer,
        )) {
          return const DeliveryFailureResult(DeliveryConflict());
        }
        if (recorded.status == LocalDeliveryCommandStatus.completed) {
          return DeliverySuccess.unit();
        }
      } else {
        final saved = await commandRepository!.save(
          LocalDeliveryCommand(
            commandId: commandId,
            driverId: request.driverId,
            targetId: request.offerId,
            type: LocalDeliveryCommandType.rejectOffer,
            status: LocalDeliveryCommandStatus.pendingSync,
            recordedAt: _clock().toUtc(),
          ),
        );
        if (saved.isFailure) return saved;
      }
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
        requested: DeliveryOfferStatus.rejecting,
      ),
    );
    if (!transition.allowed) {
      return DeliveryFailureResult(
        transition.failure ?? const InvalidDeliveryOfferTransition(),
      );
    }

    final rejected = await _offerRepository.rejectOffer(request);
    if (rejected.isFailure) return rejected;
    if (commandId != null && commandRepository != null) {
      final saved = await commandRepository!.save(
        LocalDeliveryCommand(
          commandId: commandId,
          driverId: request.driverId,
          targetId: request.offerId,
          type: LocalDeliveryCommandType.rejectOffer,
          status: LocalDeliveryCommandStatus.completed,
          recordedAt: _clock().toUtc(),
        ),
      );
      if (saved.isFailure) return saved;
    }
    return DeliverySuccess.unit();
  }
}

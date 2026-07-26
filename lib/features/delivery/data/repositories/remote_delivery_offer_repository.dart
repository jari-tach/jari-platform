import '../../domain/entities/accept_delivery_offer_request.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/delivery_result.dart';
import '../../domain/entities/reject_delivery_offer_request.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/repositories/delivery_offer_repository.dart';
import '../datasources/delivery_remote_data_source.dart';

/// Remote-backed [DeliveryOfferRepository] via [DeliveryRemoteDataSource].
///
/// Thin adapter: delegate + Entity↔Model mapping + feature-local
/// `DeliveryResult` translation. Concrete HTTP / Fake remote sources are out
/// of scope here (ADR-027 Fake implements the remote data source later).
/// Does not persist assignments — that remains [LocalDeliveryAssignmentRepository].
class RemoteDeliveryOfferRepository implements DeliveryOfferRepository {
  /// Creates a repository backed by [remoteDataSource].
  const RemoteDeliveryOfferRepository({
    required DeliveryRemoteDataSource remoteDataSource,
  }) : _remote = remoteDataSource;

  final DeliveryRemoteDataSource _remote;

  @override
  Future<DeliveryResult<List<DeliveryOffer>>> getDeliveryOffers({
    required String driverId,
  }) async {
    try {
      final models = await _remote.fetchOffers(driverId: driverId);
      return DeliverySuccess([for (final model in models) model.toEntity()]);
    } on FormatException catch (error) {
      return DeliveryFailureResult(DeliveryUnknownFailure(error.message));
    } on DeliveryFailure catch (failure) {
      return DeliveryFailureResult(failure);
    } catch (error) {
      return DeliveryFailureResult(DeliveryUnknownFailure(error.toString()));
    }
  }

  @override
  Stream<DeliveryOffer?> watchActiveOffer({required String driverId}) {
    return _remote.watchActiveOffer(driverId: driverId).map((model) {
      if (model == null) return null;
      return model.toEntity();
    });
  }

  @override
  Future<DeliveryResult<DeliveryAssignment>> acceptOffer(
    AcceptDeliveryOfferRequest request,
  ) async {
    try {
      final model = await _remote.acceptOffer(
        driverId: request.driverId,
        offerId: request.offerId,
        idempotencyKey: request.idempotencyKey,
        revision: request.revision,
        correlationId: request.correlationId,
      );
      return DeliverySuccess(model.toEntity());
    } on FormatException catch (error) {
      return DeliveryFailureResult(DeliveryUnknownFailure(error.message));
    } on DeliveryFailure catch (failure) {
      return DeliveryFailureResult(failure);
    } catch (error) {
      return DeliveryFailureResult(DeliveryUnknownFailure(error.toString()));
    }
  }

  @override
  Future<DeliveryResult<void>> rejectOffer(
    RejectDeliveryOfferRequest request,
  ) async {
    try {
      await _remote.rejectOffer(
        driverId: request.driverId,
        offerId: request.offerId,
        idempotencyKey: request.idempotencyKey,
        reasonCode: request.reasonCode,
        correlationId: request.correlationId,
      );
      return DeliverySuccess.unit();
    } on FormatException catch (error) {
      return DeliveryFailureResult(DeliveryUnknownFailure(error.message));
    } on DeliveryFailure catch (failure) {
      return DeliveryFailureResult(failure);
    } catch (error) {
      return DeliveryFailureResult(DeliveryUnknownFailure(error.toString()));
    }
  }
}

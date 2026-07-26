import 'dart:async';

import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/entities/reject_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/repositories/delivery_offer_repository.dart';

/// In-memory [DeliveryOfferRepository] for domain use-case tests only.
class FakeDeliveryOfferRepository implements DeliveryOfferRepository {
  FakeDeliveryOfferRepository({List<DeliveryOffer>? offers})
    : offers = List<DeliveryOffer>.from(offers ?? const []);

  List<DeliveryOffer> offers;
  DeliveryAssignment? acceptResult;
  DeliveryFailure? nextGetFailure;
  DeliveryFailure? nextAcceptFailure;
  DeliveryFailure? nextRejectFailure;
  Object? throwOnAccept;
  Object? throwOnReject;
  Object? throwOnGet;

  /// When non-null, [acceptOffer] awaits this before returning (stale-completion tests).
  Future<void>? acceptGate;
  Future<void>? rejectGate;

  final List<AcceptDeliveryOfferRequest> acceptRequests = [];
  final List<RejectDeliveryOfferRequest> rejectRequests = [];
  int getCallCount = 0;
  int acceptCallCount = 0;
  int rejectCallCount = 0;

  final _activeController = StreamController<DeliveryOffer?>.broadcast();

  void emitActive(DeliveryOffer? offer) => _activeController.add(offer);

  void dispose() {
    _activeController.close();
  }

  @override
  Future<DeliveryResult<List<DeliveryOffer>>> getDeliveryOffers({
    required String driverId,
  }) async {
    getCallCount++;
    if (throwOnGet != null) {
      throw throwOnGet!;
    }
    if (nextGetFailure != null) {
      return DeliveryFailureResult(nextGetFailure!);
    }
    return DeliverySuccess(
      offers.where((o) => o.driverId == driverId).toList(growable: false),
    );
  }

  @override
  Stream<DeliveryOffer?> watchActiveOffer({required String driverId}) =>
      _activeController.stream;

  @override
  Future<DeliveryResult<DeliveryAssignment>> acceptOffer(
    AcceptDeliveryOfferRequest request,
  ) async {
    acceptCallCount++;
    acceptRequests.add(request);
    final gate = acceptGate;
    if (gate != null) {
      await gate;
    }
    if (throwOnAccept != null) {
      throw throwOnAccept!;
    }
    if (nextAcceptFailure != null) {
      return DeliveryFailureResult(nextAcceptFailure!);
    }
    final assignment = acceptResult;
    if (assignment == null) {
      return const DeliveryFailureResult(DeliveryUnknownFailure());
    }
    return DeliverySuccess(assignment);
  }

  @override
  Future<DeliveryResult<void>> rejectOffer(
    RejectDeliveryOfferRequest request,
  ) async {
    rejectCallCount++;
    rejectRequests.add(request);
    final gate = rejectGate;
    if (gate != null) {
      await gate;
    }
    if (throwOnReject != null) {
      throw throwOnReject!;
    }
    if (nextRejectFailure != null) {
      return DeliveryFailureResult(nextRejectFailure!);
    }
    offers.removeWhere((o) => o.offerId == request.offerId);
    _activeController.add(null);
    return DeliverySuccess.unit();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/services/app_service_registry.dart';
import '../../../availability/presentation/providers/availability_providers.dart';
import '../../../delivery/data/fake/fake_delivery_remote_data_source.dart';
import '../../application/accept_delivery_offer_and_bind_busy.dart';
import '../../application/complete_delivery_and_release_busy.dart';
import '../../domain/repositories/delivery_offer_repository.dart';
import '../../domain/usecases/accept_delivery_offer.dart';
import '../../domain/usecases/advance_delivery_workflow.dart';
import '../../domain/usecases/get_active_delivery.dart';
import '../../domain/usecases/get_delivery_offers.dart';
import '../../domain/usecases/reject_delivery_offer.dart';
import '../../domain/usecases/verify_delivery_code.dart';
import '../controllers/delivery_controller.dart';
import '../state/delivery_controller_state.dart';

GetDeliveryOffers? _readGetDeliveryOffers(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.getDeliveryOffers
    : null;

AcceptDeliveryOffer? _readAcceptDeliveryOffer(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.acceptDeliveryOffer
    : null;

AcceptDeliveryOfferAndBindBusy? _readAcceptAndBind(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.acceptDeliveryOfferAndBindBusy
    : null;

RejectDeliveryOffer? _readRejectDeliveryOffer(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.rejectDeliveryOffer
    : null;

GetActiveDelivery? _readGetActiveDelivery(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.getActiveDelivery
    : null;

AdvanceDeliveryWorkflow? _readAdvanceWorkflow(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.advanceDeliveryWorkflow
    : null;

VerifyDeliveryCode? _readVerifyCode(Ref ref) => AppServiceRegistry.isInitialized
    ? AppServiceRegistry.verifyDeliveryCode
    : null;

CompleteDeliveryAndReleaseBusy? _readCompleteDelivery(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.completeDeliveryAndReleaseBusy
    : null;

DeliveryOfferRepository? _readDeliveryOfferRepository(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.deliveryOfferRepository
    : null;

String? _readDriverId(Ref ref) {
  if (!AppServiceRegistry.isInitialized) return null;
  return AppServiceRegistry.authenticationRepository?.currentSession?.driverId;
}

/// Accept preconditions from NetworkMonitor + Availability confirmation.
///
/// In debug Fake-device testing, pending local available may also qualify
/// when no Backend confirmation channel exists yet (see DEV-ONLY confirmer).
DeliveryAcceptPreconditions _readAcceptPreconditions(Ref ref) {
  final online = AppServiceRegistry.isInitialized
      ? (AppServiceRegistry.networkMonitor?.isOnline ?? false)
      : false;
  final availability = ref.watch(availabilityControllerProvider);
  var confirmed = availability.isConfirmedAvailable;

  if (!confirmed &&
      kDebugMode &&
      !AppConfig.isProduction &&
      AppServiceRegistry.isInitialized &&
      AppServiceRegistry.deliveryRemoteDataSource
          is FakeDeliveryRemoteDataSource) {
    // DEV-ONLY fallback while Fake-trial confirmation races/settles.
    confirmed =
        availability.isPendingConfirmation || availability.isConfirmedAvailable;
  }

  return DeliveryAcceptPreconditions(
    connectivityOnline: online,
    isConfirmedAvailable: confirmed,
  );
}

/// Presentation-level refresh after ADR-025 bind — not widget logic.
Future<void> _refreshAvailability(Ref ref) async {
  await ref.read(availabilityControllerProvider.notifier).initialize();
}

final deliveryControllerProvider =
    NotifierProvider<DeliveryController, DeliveryControllerState>(
      () => DeliveryController(
        getOffersReader: _readGetDeliveryOffers,
        acceptReader: _readAcceptDeliveryOffer,
        acceptAndBindReader: _readAcceptAndBind,
        rejectReader: _readRejectDeliveryOffer,
        getActiveReader: _readGetActiveDelivery,
        advanceWorkflowReader: _readAdvanceWorkflow,
        verifyCodeReader: _readVerifyCode,
        completeDeliveryReader: _readCompleteDelivery,
        offerRepositoryReader: _readDeliveryOfferRepository,
        driverIdReader: _readDriverId,
        acceptPreconditionsReader: _readAcceptPreconditions,
        availabilityRefreshReader: _refreshAvailability,
      ),
    );

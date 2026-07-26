import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_offer_model.dart';
import 'package:saeq_driver/features/delivery/data/repositories/remote_delivery_offer_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/entities/reject_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import '../../helpers/delivery_fixtures.dart';
import '../../helpers/recording_delivery_remote_data_source.dart';

void main() {
  late RecordingDeliveryRemoteDataSource remote;
  late RemoteDeliveryOfferRepository repo;

  setUp(() {
    remote = RecordingDeliveryRemoteDataSource();
    repo = RemoteDeliveryOfferRepository(remoteDataSource: remote);
  });

  tearDown(() {
    remote.dispose();
  });

  group('RemoteDeliveryOfferRepository', () {
    test('getDeliveryOffers delegates and maps models', () async {
      remote.offers = [DeliveryOfferModel.fromEntity(sampleOffer())];
      final result = await repo.getDeliveryOffers(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, [sampleOffer()]);
      expect(remote.fetchCount, 1);
      expect(remote.lastFetchDriverId, 'drv-1');
    });

    test('acceptOffer delegates and maps assignment', () async {
      remote.acceptResult = DeliveryAssignmentModel.fromEntity(
        sampleAssignment(),
      );
      final result = await repo.acceptOffer(
        AcceptDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: 'off-1',
          idempotencyKey: 'idem-1',
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
      );
      expect(result.valueOrNull, sampleAssignment());
      expect(remote.acceptCount, 1);
      expect(remote.lastAcceptIdempotencyKey, 'idem-1');
    });

    test('rejectOffer delegates successfully', () async {
      final result = await repo.rejectOffer(
        RejectDeliveryOfferRequest(driverId: 'drv-1', offerId: 'off-1'),
      );
      expect(result.isSuccess, isTrue);
      expect(remote.rejectCount, 1);
      expect(remote.lastRejectOfferId, 'off-1');
    });

    test('FormatException maps to DeliveryUnknownFailure', () async {
      remote.offers = [
        DeliveryOfferModel.fromJson(
          DeliveryOfferModel.fromEntity(sampleOffer()).toJson()
            ..['status'] = 'teleporting',
        ),
      ];
      final result = await repo.getDeliveryOffers(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryUnknownFailure>());
    });

    test('DeliveryFailure passthrough', () async {
      remote.throwOnFetch = const DeliveryOfferTaken();
      final result = await repo.getDeliveryOffers(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryOfferTaken>());
    });

    test('unknown exception maps to DeliveryUnknownFailure', () async {
      remote.throwOnAccept = StateError('boom');
      remote.acceptResult = DeliveryAssignmentModel.fromEntity(
        sampleAssignment(),
      );
      final result = await repo.acceptOffer(
        AcceptDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: 'off-1',
          idempotencyKey: 'idem-1',
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
      );
      expect(result.failureOrNull, isA<DeliveryUnknownFailure>());
      expect(result.failureOrNull!.message, contains('boom'));
    });

    test('reject FormatException and DeliveryFailure paths', () async {
      remote.throwOnReject = const FormatException('bad reject payload');
      final formatResult = await repo.rejectOffer(
        RejectDeliveryOfferRequest(driverId: 'drv-1', offerId: 'off-1'),
      );
      expect(formatResult.failureOrNull, isA<DeliveryUnknownFailure>());

      remote.throwOnReject = const DeliveryConflict();
      final failureResult = await repo.rejectOffer(
        RejectDeliveryOfferRequest(driverId: 'drv-1', offerId: 'off-1'),
      );
      expect(failureResult.failureOrNull, isA<DeliveryConflict>());
    });

    test('watchActiveOffer maps null and models', () async {
      final events = <Object?>[];
      final sub = repo.watchActiveOffer(driverId: 'drv-1').listen(events.add);
      remote.emitActive(null);
      remote.emitActive(DeliveryOfferModel.fromEntity(sampleOffer()));
      await Future<void>.delayed(Duration.zero);
      expect(events[0], isNull);
      expect(events[1], sampleOffer());
      await sub.cancel();
    });
  });
}

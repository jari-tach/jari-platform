import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/data/models/driver_availability_wire.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/delivery/data/models/offer_summary_wire.dart';
import 'package:saeq_driver/features/profile/data/models/driver_profile_wire.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

void main() {
  group('DriverProfileWire', () {
    test('maps active profile to domain', () {
      final wire = DriverProfileWire.fromJson({
        'driverId': '11111111-1111-4111-8111-111111111111',
        'displayName': 'Driver One',
        'phoneMasked': '+9665****5678',
        'locale': 'ar-SA',
        'status': 'active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'vehicleType': 'motorcycle',
      });
      final domain = wire.toDomain();
      expect(domain.fullName, 'Driver One');
      expect(domain.phoneNumber, '+9665****5678');
      expect(domain.accountStatus, AccountStatus.verified);
      expect(domain.employmentStatus, EmploymentStatus.active);
      expect(domain.vehicleType, 'motorcycle');
    });

    test('maps suspended status', () {
      final wire = DriverProfileWire.fromJson({
        'driverId': '11111111-1111-4111-8111-111111111111',
        'displayName': 'Driver One',
        'phoneMasked': '+9665****5678',
        'locale': 'ar-SA',
        'status': 'suspended',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      });
      expect(wire.toDomain().accountStatus, AccountStatus.suspended);
    });
  });

  group('DriverAvailabilityWire', () {
    test('maps backend statuses', () {
      expect(
        DriverAvailabilityWire.mapStatus('available'),
        AvailabilityStatus.available,
      );
      expect(
        DriverAvailabilityWire.mapStatus('suspended'),
        AvailabilityStatus.unavailable,
      );
      expect(
        DriverAvailabilityWire.toWireStatus(AvailabilityStatus.available),
        'available',
      );
      expect(
        DriverAvailabilityWire.toWireStatus(AvailabilityStatus.busy),
        isNull,
      );
    });

    test('toDomain keeps pendingSync false and source server', () {
      final wire = DriverAvailabilityWire.fromJson({
        'status': 'available',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });
      final domain = wire.toDomain(driverId: 'd1');
      expect(domain.pendingSync, isFalse);
      expect(domain.source.name, 'server');
    });
  });

  group('OfferSummaryWire', () {
    test('maps to DeliveryOfferModel without customer PII fields', () {
      final wire = OfferSummaryWire.fromJson({
        'offerId': '22222222-2222-4222-8222-222222222222',
        'status': 'offered',
        'estimatedDistanceMeters': 1200,
        'estimatedDurationSeconds': 600,
        'compensation': {'amount': 12.5, 'currency': 'SAR'},
        'pickup': {
          'label': 'Merchant A',
          'location': {'latitude': 24.7, 'longitude': 46.7},
        },
        'dropoff': {
          'label': 'District B',
          'location': {'latitude': 24.8, 'longitude': 46.8},
        },
        'expiresAt': '2026-01-01T01:00:00.000Z',
        'aggregateVersion': 3,
      });
      final model = wire.toDeliveryOfferModel(driverId: 'driver-1');
      expect(model.offerId, wire.offerId);
      expect(model.revision, '3');
      expect(model.order.pickupLabel, 'Merchant A');
      expect(model.order.dropoffLabel, 'District B');
      expect(model.order.merchantDisplayName, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/features/delivery/data/models/batch_summary_wire.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_lifecycle_wire.dart';
import 'package:saeq_driver/features/delivery/data/remote/customer_contact_memory_cache.dart';

void main() {
  group('CustomerContactMemoryCache', () {
    test('stores and clears on delivery completion', () {
      final cache = CustomerContactMemoryCache();
      cache.set(
        CustomerContactWire(
          deliveryId: 'd1',
          name: 'Synthetic',
          phoneNumber: '+966500000000',
          availableUntil: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(cache.current?.name, 'Synthetic');
      cache.clearForDelivery('d1');
      expect(cache.current, isNull);
    });

    test('clears on logout', () {
      final cache = CustomerContactMemoryCache()
        ..set(
          CustomerContactWire(
            deliveryId: 'd1',
            name: 'Synthetic',
            phoneNumber: '+966500000000',
            availableUntil: DateTime.utc(2026, 1, 1),
          ),
        );
      cache.clear();
      expect(cache.current, isNull);
    });
  });

  group('BatchSummaryWire', () {
    test('upcoming stops must not carry contact fields', () {
      final batch = BatchSummaryWire.fromJson({
        'batchId': 'b1',
        'currentStopSequence': 1,
        'aggregateVersion': 1,
        'stops': [
          {
            'sequence': 1,
            'deliveryId': 'd1',
            'stopType': 'pickup',
            'label': 'Merchant',
          },
          {
            'sequence': 2,
            'deliveryId': 'd2',
            'stopType': 'dropoff',
            'label': 'District',
          },
        ],
      });
      expect(batch.upcomingStopsHaveContactFields, isFalse);
    });
  });

  test('no manual arrival endpoint in DriverApiPaths', () {
    expect(DriverApiPaths.deliveryArrival('x').contains('manual'), isFalse);
    expect(DriverApiPaths.deliveryArrival('x'), endsWith('/arrival'));
  });

  test('DeliveryMutationResponseWire parses contract shape', () {
    final wire = DeliveryMutationResponseWire.fromJson({
      'deliveryId': '00000000-0000-4000-8000-000000000020',
      'state': 'pickupConfirmedManually',
      'aggregateVersion': 2,
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });
    expect(wire.state, 'pickupConfirmedManually');
  });
}

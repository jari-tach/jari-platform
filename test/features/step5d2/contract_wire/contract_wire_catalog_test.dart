/// STEP 5D-2 contract wire catalog — exactly 23/23 endpoints, no manual
/// arrival endpoint anywhere.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';

import 'contract_wire_harness.dart';

void main() {
  const expectedEndpoints = <String>{
    // Auth (4)
    'POST /v1/auth/otp/request',
    'POST /v1/auth/otp/verify',
    'POST /v1/auth/token/refresh',
    'POST /v1/auth/logout',
    // Driver (3)
    'GET /v1/drivers/me',
    'PATCH /v1/drivers/me',
    'GET /v1/drivers/me/compliance',
    // Availability (2)
    'GET /v1/drivers/me/availability',
    'PUT /v1/drivers/me/availability',
    // Offers (4)
    'GET /v1/offers',
    'GET /v1/offers/{offerId}',
    'POST /v1/offers/{offerId}/accept',
    'POST /v1/offers/{offerId}/reject',
    // Deliveries (7)
    'GET /v1/deliveries/active',
    'GET /v1/deliveries/{deliveryId}',
    'POST /v1/deliveries/{deliveryId}/pickup-confirmation',
    'POST /v1/deliveries/{deliveryId}/arrival',
    'POST /v1/deliveries/{deliveryId}/delivery-confirmation',
    'POST /v1/deliveries/{deliveryId}/cancel',
    'POST /v1/deliveries/{deliveryId}/issues',
    // Batches (2)
    'GET /v1/batches/active',
    'GET /v1/batches/{batchId}',
    // Customer contact (1)
    'GET /v1/deliveries/{deliveryId}/customer-contact',
  };

  test('catalog covers exactly 23 endpoints', () {
    expect(expectedEndpoints, hasLength(23));
    expect(contractWireEndpointCatalog, hasLength(23));

    final catalogKeys = contractWireEndpointCatalog.map((e) => e.key).toSet();
    expect(catalogKeys, hasLength(23), reason: 'catalog keys must be unique');
    expect(catalogKeys, expectedEndpoints);
  });

  test('every catalog endpoint is assigned to an existing wire test file', () {
    const files = {
      'auth',
      'driver_profile',
      'availability',
      'offers',
      'deliveries',
      'batches_and_contact',
    };
    for (final endpoint in contractWireEndpointCatalog) {
      expect(files, contains(endpoint.coveredBy));
    }
    // Group sizes match the contracts-v0.1.0 resource split.
    expect(catalogSlice('auth'), hasLength(4));
    expect(catalogSlice('driver_profile'), hasLength(3));
    expect(catalogSlice('availability'), hasLength(2));
    expect(catalogSlice('offers'), hasLength(4));
    expect(catalogSlice('deliveries'), hasLength(7));
    expect(catalogSlice('batches_and_contact'), hasLength(3));
  });

  test('NO manual-arrival endpoint exists (arrival is automatic-only, '
      'ADR-029)', () {
    final forbidden = RegExp(
      r'manual[-_]?arrival|arrival[-_]?manual',
      caseSensitive: false,
    );
    for (final endpoint in contractWireEndpointCatalog) {
      expect(
        forbidden.hasMatch(endpoint.path),
        isFalse,
        reason: '${endpoint.path} must not be a manual arrival endpoint',
      );
    }

    // DriverApiPaths itself must not build a manual arrival path.
    final allPaths = <String>[
      DriverApiPaths.otpRequest,
      DriverApiPaths.otpVerify,
      DriverApiPaths.tokenRefresh,
      DriverApiPaths.logout,
      DriverApiPaths.driverMe,
      DriverApiPaths.driverCompliance,
      DriverApiPaths.driverAvailability,
      DriverApiPaths.offers,
      DriverApiPaths.offerById('x'),
      DriverApiPaths.offerAccept('x'),
      DriverApiPaths.offerReject('x'),
      DriverApiPaths.deliveriesActive,
      DriverApiPaths.deliveryById('x'),
      DriverApiPaths.deliveryPickupConfirmation('x'),
      DriverApiPaths.deliveryArrival('x'),
      DriverApiPaths.deliveryConfirmation('x'),
      DriverApiPaths.deliveryCancel('x'),
      DriverApiPaths.deliveryIssues('x'),
      DriverApiPaths.deliveryCustomerContact('x'),
      DriverApiPaths.batchesActive,
      DriverApiPaths.batchById('x'),
    ];
    for (final path in allPaths) {
      expect(forbidden.hasMatch(path), isFalse);
      expect(path.toLowerCase().contains('manual'), isFalse);
    }
    expect(DriverApiPaths.deliveryArrival('x'), endsWith('/arrival'));
  });

  test('catalog path templates match DriverApiPaths builders', () {
    expect(
      templatePath(DriverApiPaths.offerById(fixtureOfferId)),
      '/v1/offers/{offerId}',
    );
    expect(
      templatePath(DriverApiPaths.deliveryById(fixtureDeliveryId)),
      '/v1/deliveries/{deliveryId}',
    );
    expect(
      templatePath(DriverApiPaths.batchById(fixtureBatchId)),
      '/v1/batches/{batchId}',
    );
    expect(
      templatePath(DriverApiPaths.deliveryCustomerContact(fixtureDeliveryId)),
      '/v1/deliveries/{deliveryId}/customer-contact',
    );
  });
}

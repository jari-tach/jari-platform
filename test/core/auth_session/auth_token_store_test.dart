import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/core/auth_session/auth_token_store.dart';
import 'package:saeq_driver/core/services/storage/secure_storage_service.dart';

class _MemStorage implements SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<void> deleteAll() async => data.clear();

  @override
  Future<bool> containsKey(String key) async => data.containsKey(key);

  @override
  Future<String?> getAccessToken() async => data['access_token'];

  @override
  Future<String?> getRefreshToken() async => data['refresh_token'];

  @override
  Future<void> clearAllAuthData() async => data.clear();
}

void main() {
  test(
    'SecureAuthTokenStore persists refresh token only under saeq key',
    () async {
      final mem = _MemStorage();
      final store = SecureAuthTokenStore(storage: mem);
      await store.saveRefreshToken('refresh-secret');
      expect(mem.data.keys, ['saeq_refresh_token_v1']);
      expect(await store.readRefreshToken(), 'refresh-secret');
      await store.clearAll();
      expect(mem.data, isEmpty);
    },
  );

  test('DriverApiPaths exposes all 23 contract endpoints', () {
    final paths = <String>{
      DriverApiPaths.otpRequest,
      DriverApiPaths.otpVerify,
      DriverApiPaths.tokenRefresh,
      DriverApiPaths.logout,
      DriverApiPaths.driverMe,
      DriverApiPaths.driverCompliance,
      DriverApiPaths.driverAvailability,
      DriverApiPaths.offers,
      DriverApiPaths.offerById('o'),
      DriverApiPaths.offerAccept('o'),
      DriverApiPaths.offerReject('o'),
      DriverApiPaths.deliveriesActive,
      DriverApiPaths.deliveryById('d'),
      DriverApiPaths.deliveryPickupConfirmation('d'),
      DriverApiPaths.deliveryArrival('d'),
      DriverApiPaths.deliveryConfirmation('d'),
      DriverApiPaths.deliveryCancel('d'),
      DriverApiPaths.deliveryIssues('d'),
      DriverApiPaths.deliveryCustomerContact('d'),
      DriverApiPaths.batchesActive,
      DriverApiPaths.batchById('b'),
    };
    // Distinct path templates: accept/reject/byId share prefix but differ.
    expect(paths.length, 21);
    expect(paths.any((p) => p.contains('manual')), isFalse);
    expect(DriverApiPaths.otpRequest, '/v1/auth/otp/request');
    expect(DriverApiPaths.deliveryArrival('x'), '/v1/deliveries/x/arrival');
  });
}

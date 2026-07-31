import '../../../../core/backend_configuration/driver_api_paths.dart';
import '../../../../core/network/saeq_api_client.dart';
import '../models/driver_compliance_wire.dart';
import '../models/driver_profile_wire.dart';
import 'driver_profile_remote_data_source.dart';

final class HttpDriverProfileRemoteDataSource
    implements DriverProfileRemoteDataSource {
  HttpDriverProfileRemoteDataSource({required this._api});

  final SaeqApiClient _api;

  @override
  Future<DriverProfileWire> getMe() async {
    final response = await _api.get<Map<String, dynamic>>(
      DriverApiPaths.driverMe,
    );
    return DriverProfileWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<DriverProfileWire> patchMe({
    required String idempotencyKey,
    String? displayName,
    String? locale,
    String? vehicleType,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      DriverApiPaths.driverMe,
      data: {
        'displayName': ?displayName,
        'locale': ?locale,
        'vehicleType': ?vehicleType,
      },
      idempotencyKey: idempotencyKey,
    );
    return DriverProfileWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<DriverComplianceWire> getCompliance() async {
    final response = await _api.get<Map<String, dynamic>>(
      DriverApiPaths.driverCompliance,
    );
    return DriverComplianceWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

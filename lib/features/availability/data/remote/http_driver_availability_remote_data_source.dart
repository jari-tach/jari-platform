import '../../../../core/backend_configuration/driver_api_paths.dart';
import '../../../../core/network/saeq_api_client.dart';
import '../models/driver_availability_wire.dart';
import 'driver_availability_remote_data_source.dart';

final class HttpDriverAvailabilityRemoteDataSource
    implements DriverAvailabilityRemoteDataSource {
  HttpDriverAvailabilityRemoteDataSource({required this._api});

  final SaeqApiClient _api;

  @override
  Future<DriverAvailabilityWire> getAvailability() async {
    final response = await _api.get<Map<String, dynamic>>(
      DriverApiPaths.driverAvailability,
    );
    return DriverAvailabilityWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<DriverAvailabilityWire> putAvailability({
    required String status,
    required String idempotencyKey,
  }) async {
    final response = await _api.put<Map<String, dynamic>>(
      DriverApiPaths.driverAvailability,
      data: {'status': status},
      idempotencyKey: idempotencyKey,
    );
    return DriverAvailabilityWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

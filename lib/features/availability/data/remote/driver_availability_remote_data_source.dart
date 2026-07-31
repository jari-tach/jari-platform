import '../models/driver_availability_wire.dart';

abstract interface class DriverAvailabilityRemoteDataSource {
  Future<DriverAvailabilityWire> getAvailability();
  Future<DriverAvailabilityWire> putAvailability({
    required String status,
    required String idempotencyKey,
  });
}

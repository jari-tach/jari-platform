import '../models/driver_compliance_wire.dart';
import '../models/driver_profile_wire.dart';

abstract interface class DriverProfileRemoteDataSource {
  Future<DriverProfileWire> getMe();
  Future<DriverProfileWire> patchMe({
    required String idempotencyKey,
    String? displayName,
    String? locale,
    String? vehicleType,
  });
  Future<DriverComplianceWire> getCompliance();
}

import '../models/persisted_driver_availability_record.dart';

/// Local persistence port for availability snapshots (no domain policies).
abstract interface class DriverAvailabilityLocalDataSource {
  /// Returns null when no snapshot exists.
  Future<PersistedDriverAvailabilityRecord?> read();

  Future<void> write(PersistedDriverAvailabilityRecord record);

  Future<void> clear();
}

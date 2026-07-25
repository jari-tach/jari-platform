import 'package:saeq_driver/features/availability/data/datasources/driver_availability_local_data_source.dart';
import 'package:saeq_driver/features/availability/data/models/persisted_driver_availability_record.dart';

/// In-memory local datasource for availability repository tests only.
class InMemoryDriverAvailabilityLocalDataSource
    implements DriverAvailabilityLocalDataSource {
  PersistedDriverAvailabilityRecord? record;
  bool failReads = false;
  bool failWrites = false;
  bool failClears = false;
  int writeCount = 0;
  int clearCount = 0;
  int readCount = 0;

  @override
  Future<PersistedDriverAvailabilityRecord?> read() async {
    readCount++;
    if (failReads) {
      throw StateError('forced read failure');
    }
    return record;
  }

  @override
  Future<void> write(PersistedDriverAvailabilityRecord value) async {
    writeCount++;
    if (failWrites) {
      throw StateError('forced write failure');
    }
    record = value;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    if (failClears) {
      throw StateError('forced clear failure');
    }
    record = null;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';

void main() {
  final changedAt = DateTime.utc(2026, 7, 25, 12);

  group('DriverAvailability invariants', () {
    test('rejects empty driverId', () {
      expect(
        () => DriverAvailability(
          driverId: '  ',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: changedAt,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative revision', () {
      expect(
        () => DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: changedAt,
          revision: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects busy from localUserAction', () {
      expect(
        () => DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: changedAt,
          activeAssignmentId: 'asg-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects busy from restoredLocalState alone', () {
      expect(
        () => DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.restoredLocalState,
          lastChangedAt: changedAt,
          activeAssignmentId: 'asg-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows busy from system/server with assignment id', () {
      final a = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.busy,
        source: AvailabilitySource.system,
        lastChangedAt: changedAt,
        activeAssignmentId: 'asg-1',
      );
      expect(a.status, AvailabilityStatus.busy);
      expect(a.activeAssignmentId, 'asg-1');
    });

    test('rejects activeAssignmentId when not busy', () {
      expect(
        () => DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: changedAt,
          lastConfirmedAt: changedAt,
          activeAssignmentId: 'asg-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sovereign driverId is immutable via copyWith', () {
      final a = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.unavailable,
        source: AvailabilitySource.localUserAction,
        lastChangedAt: changedAt,
      );
      final b = a.copyWith(status: AvailabilityStatus.offline);
      expect(b.driverId, 'drv-1');
      expect(b.status, AvailabilityStatus.offline);
    });

    test('restored available is not confirmed available', () {
      final a = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.available,
        source: AvailabilitySource.restoredLocalState,
        lastChangedAt: changedAt,
        lastConfirmedAt: changedAt,
      );
      expect(a.isConfirmedAvailable, isFalse);
      expect(a.isRestoredUnconfirmedAvailable, isTrue);
    });

    test('pendingSync available is not confirmed', () {
      final a = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.available,
        source: AvailabilitySource.localUserAction,
        lastChangedAt: changedAt,
        lastConfirmedAt: changedAt,
        pendingSync: true,
      );
      expect(a.isConfirmedAvailable, isFalse);
    });

    test('server-confirmed available is confirmed', () {
      final a = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.available,
        source: AvailabilitySource.server,
        lastChangedAt: changedAt,
        lastConfirmedAt: changedAt,
        pendingSync: false,
        revision: 3,
      );
      expect(a.isConfirmedAvailable, isTrue);
    });

    test('equality and copyWith clear flags', () {
      final a = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.available,
        source: AvailabilitySource.server,
        lastChangedAt: changedAt,
        lastConfirmedAt: changedAt,
        revision: 1,
        reason: 'ok',
      );
      final b = a.copyWith(clearLastConfirmedAt: true, clearRevision: true);
      expect(b.lastConfirmedAt, isNull);
      expect(b.revision, isNull);
      expect(a, isNot(equals(b)));
      expect(
        a,
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: changedAt,
          lastConfirmedAt: changedAt,
          revision: 1,
          reason: 'ok',
        ),
      );
    });
  });
}

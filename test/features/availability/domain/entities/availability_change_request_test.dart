import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_change_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 18);

  group('AvailabilityChangeRequest', () {
    test('driver-authored busy request constructs without ArgumentError', () {
      final request = AvailabilityChangeRequest(
        driverId: 'drv-1',
        requestedStatus: AvailabilityStatus.busy,
        actor: AvailabilityActor.driver,
        requestedAt: at,
      );
      expect(request.requestedStatus, AvailabilityStatus.busy);
      expect(request.actor, AvailabilityActor.driver);
    });

    test('empty driverId remains a structural ArgumentError', () {
      expect(
        () => AvailabilityChangeRequest(
          driverId: '  ',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

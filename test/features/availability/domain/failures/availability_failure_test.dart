import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';

void main() {
  group('AvailabilityFailure codes', () {
    test('each failure exposes stable machine-readable code', () {
      final samples = <AvailabilityFailure>[
        const AvailabilityUnauthenticated(),
        const DriverProfileMissing(),
        const DriverAccountSuspended(),
        const DriverAccountInactive(),
        const DriverEmploymentIneligible(),
        const ActiveAssignmentConflict(),
        const ManualBusyTransitionDenied(),
        const InvalidAvailabilityTransition(),
        const AvailabilityOffline(),
        const AvailabilityConfirmationRequired(),
        const AvailabilityStateStale(),
        const AvailabilitySyncConflict(),
        const AvailabilityPersistenceFailure(),
        const AvailabilitySecurityPolicyDenied(),
        const AvailabilityUnknownFailure(),
      ];

      final codes = samples.map((f) => f.code).toSet();
      expect(codes.length, samples.length);
      for (final f in samples) {
        expect(f.code, startsWith('availability.'));
        expect(f.toString(), contains(f.code));
      }
    });
  });
}

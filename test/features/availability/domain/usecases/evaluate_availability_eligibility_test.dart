import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/evaluate_availability_eligibility.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  group('EvaluateAvailabilityEligibility', () {
    test('delegates deterministic policy decision', () {
      const uc = EvaluateAvailabilityEligibility();
      final allowed = uc(
        const AvailabilityEligibilityInput(
          authenticated: true,
          profileExists: true,
          accountStatus: AccountStatus.verified,
          employmentStatus: EmploymentStatus.active,
          hasActiveAssignment: false,
          connectivityAvailable: true,
          securityPolicyAllows: true,
        ),
      );
      expect(allowed.allowed, isTrue);
      expect(allowed.effectiveStatus, AvailabilityStatus.available);

      final denied = uc(
        const AvailabilityEligibilityInput(
          authenticated: false,
          profileExists: true,
          accountStatus: AccountStatus.verified,
          employmentStatus: EmploymentStatus.active,
          hasActiveAssignment: false,
          connectivityAvailable: true,
          securityPolicyAllows: true,
        ),
      );
      expect(denied.failure, isA<AvailabilityUnauthenticated>());
    });

    test('no repository call occurs', () {
      final fake = FakeDriverAvailabilityRepository();
      const uc = EvaluateAvailabilityEligibility();
      uc(
        const AvailabilityEligibilityInput(
          authenticated: true,
          profileExists: true,
          accountStatus: AccountStatus.verified,
          employmentStatus: EmploymentStatus.active,
          hasActiveAssignment: false,
          connectivityAvailable: true,
          securityPolicyAllows: true,
        ),
      );
      expect(fake.getCurrentCallCount, 0);
      expect(fake.requestCallCount, 0);
      fake.dispose();
    });
  });
}

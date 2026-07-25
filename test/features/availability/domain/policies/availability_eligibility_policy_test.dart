import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/policies/availability_eligibility_policy.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

void main() {
  const policy = AvailabilityEligibilityPolicy();

  AvailabilityEligibilityInput eligible({
    bool authenticated = true,
    bool profileExists = true,
    AccountStatus accountStatus = AccountStatus.verified,
    EmploymentStatus employmentStatus = EmploymentStatus.active,
    bool hasActiveAssignment = false,
    bool connectivityAvailable = true,
    bool securityPolicyAllows = true,
    bool? locationPermissionGranted,
  }) => AvailabilityEligibilityInput(
    authenticated: authenticated,
    profileExists: profileExists,
    accountStatus: accountStatus,
    employmentStatus: employmentStatus,
    hasActiveAssignment: hasActiveAssignment,
    connectivityAvailable: connectivityAvailable,
    securityPolicyAllows: securityPolicyAllows,
    locationPermissionGranted: locationPermissionGranted,
  );

  group('AvailabilityEligibilityPolicy', () {
    test('eligible driver allowed', () {
      final d = policy.evaluate(eligible());
      expect(d.allowed, isTrue);
      expect(d.failure, isNull);
      expect(d.effectiveStatus, AvailabilityStatus.available);
      expect(d.requiredAction, AvailabilityRequiredAction.none);
      expect(d.retryable, isFalse);
      expect(d.policyVersion, AvailabilityEligibilityPolicy.policyVersion);
    });

    test('unauthenticated denied', () {
      final d = policy.evaluate(eligible(authenticated: false));
      expect(d.allowed, isFalse);
      expect(d.failure, isA<AvailabilityUnauthenticated>());
      expect(d.effectiveStatus, AvailabilityStatus.offline);
      expect(d.requiredAction, AvailabilityRequiredAction.signIn);
      expect(d.retryable, isFalse);
    });

    test('profile missing denied', () {
      final d = policy.evaluate(eligible(profileExists: false));
      expect(d.allowed, isFalse);
      expect(d.failure, isA<DriverProfileMissing>());
      expect(d.requiredAction, AvailabilityRequiredAction.completeProfile);
      expect(d.effectiveStatus, AvailabilityStatus.unavailable);
    });

    test('suspended account denied', () {
      final d = policy.evaluate(
        eligible(accountStatus: AccountStatus.suspended),
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<DriverAccountSuspended>());
      expect(d.effectiveStatus, AvailabilityStatus.unavailable);
      expect(d.retryable, isFalse);
    });

    test('blocked/rejected account denied', () {
      final d = policy.evaluate(
        eligible(accountStatus: AccountStatus.rejected),
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<DriverAccountInactive>());
      expect(d.requiredAction, AvailabilityRequiredAction.contactSupport);
    });

    test('inactive account denied (rejected path)', () {
      final d = policy.evaluate(
        eligible(accountStatus: AccountStatus.rejected),
      );
      expect(d.failure!.code, 'availability.account_inactive');
    });

    test('employment ineligible denied', () {
      final d = policy.evaluate(
        eligible(employmentStatus: EmploymentStatus.inactive),
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<DriverEmploymentIneligible>());
    });

    test('offline denied for confirmed available', () {
      final d = policy.evaluate(eligible(connectivityAvailable: false));
      expect(d.allowed, isFalse);
      expect(d.failure, isA<AvailabilityOffline>());
      expect(d.effectiveStatus, AvailabilityStatus.offline);
      expect(d.retryable, isTrue);
      expect(d.requiredAction, AvailabilityRequiredAction.waitConnectivity);
    });

    test('active assignment conflict denied', () {
      final d = policy.evaluate(eligible(hasActiveAssignment: true));
      expect(d.allowed, isFalse);
      expect(d.failure, isA<ActiveAssignmentConflict>());
      expect(d.effectiveStatus, AvailabilityStatus.busy);
      expect(d.retryable, isTrue);
      expect(d.requiredAction, AvailabilityRequiredAction.waitAssignment);
    });

    test('production security policy denied', () {
      final d = policy.evaluate(eligible(securityPolicyAllows: false));
      expect(d.allowed, isFalse);
      expect(d.failure, isA<AvailabilitySecurityPolicyDenied>());
      expect(d.retryable, isFalse);
      expect(d.requiredAction, AvailabilityRequiredAction.contactSupport);
      expect(d.effectiveStatus, AvailabilityStatus.unavailable);
    });

    test('denial precedence is deterministic (security before auth)', () {
      final d = policy.evaluate(
        eligible(authenticated: false, securityPolicyAllows: false),
      );
      expect(d.failure, isA<AvailabilitySecurityPolicyDenied>());
    });

    test('denial precedence: auth before profile', () {
      final d = policy.evaluate(
        eligible(authenticated: false, profileExists: false),
      );
      expect(d.failure, isA<AvailabilityUnauthenticated>());
    });

    test('denial precedence: profile before suspended', () {
      final d = policy.evaluate(
        eligible(profileExists: false, accountStatus: AccountStatus.suspended),
      );
      expect(d.failure, isA<DriverProfileMissing>());
    });

    test('denial precedence: suspended before employment', () {
      final d = policy.evaluate(
        eligible(
          accountStatus: AccountStatus.suspended,
          employmentStatus: EmploymentStatus.terminated,
        ),
      );
      expect(d.failure, isA<DriverAccountSuspended>());
    });

    test('location permission ignored (deferred architecture)', () {
      final deniedLoc = policy.evaluate(
        eligible(locationPermissionGranted: false),
      );
      expect(deniedLoc.allowed, isTrue);

      final grantedLoc = policy.evaluate(
        eligible(locationPermissionGranted: true),
      );
      expect(grantedLoc.allowed, isTrue);
    });

    test('pending account may be eligible when otherwise valid', () {
      final d = policy.evaluate(eligible(accountStatus: AccountStatus.pending));
      expect(d.allowed, isTrue);
    });

    test('failure codes are deterministic', () {
      expect(
        const AvailabilityUnauthenticated().code,
        'availability.unauthenticated',
      );
      expect(const DriverProfileMissing().code, 'availability.profile_missing');
      expect(const AvailabilityOffline().code, 'availability.offline');
    });
  });
}

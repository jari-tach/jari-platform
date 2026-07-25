import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../domain/entities/availability_eligibility_input.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/failures/availability_failure.dart';

/// Resolves eligibility for becoming available without fabricating profile facts.
///
/// Production default is deny-safe: session authentication alone is never
/// treated as proof of eligibility. [DriverProfile] does not yet expose every
/// field required by [AvailabilityEligibilityInput] (assignment conflict,
/// connectivity, and security-policy allowance) without inference — so this
/// reader returns a typed failure until an authorized integration supplies a
/// complete authoritative mapping.
AvailabilityResult<AvailabilityEligibilityInput> readAvailabilityEligibility(
  Ref ref,
  String driverId,
) {
  final normalizedId = driverId.trim();
  if (normalizedId.isEmpty) {
    return const AvailabilityFailureResult(AvailabilityUnauthenticated());
  }

  if (!AppServiceRegistry.isInitialized) {
    return const AvailabilityFailureResult(
      DriverProfileMissing(
        'Authoritative availability eligibility is not available.',
      ),
    );
  }

  final session = AppServiceRegistry.authenticationRepository?.currentSession;
  if (session == null || session.isExpired) {
    return const AvailabilityFailureResult(AvailabilityUnauthenticated());
  }

  if (session.driverId != normalizedId) {
    return const AvailabilityFailureResult(
      AvailabilitySecurityPolicyDenied(
        'Eligibility identity does not match the authenticated session.',
      ),
    );
  }

  // Authenticated session is required but never sufficient. Do not invent
  // profileExists, accountStatus, employment, assignment, or connectivity.
  return const AvailabilityFailureResult(
    DriverProfileMissing(
      'Authoritative availability eligibility is not loaded.',
    ),
  );
}

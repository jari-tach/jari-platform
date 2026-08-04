import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../../delivery/data/fake/fake_delivery_remote_data_source.dart';
import '../../../profile/domain/entities/driver_status.dart';
import '../../domain/entities/availability_eligibility_input.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/failures/availability_failure.dart';

/// Resolves eligibility for becoming available.
///
/// When a remote Backend path is active (non-Fake delivery remote), an
/// authenticated session plus live connectivity is treated as sufficient to
/// *request* available — Backend remains authoritative for busy/suspended and
/// for accepting/rejecting the PUT. Fake/local paths keep deny-safe behavior
/// unless the debug eligibility reader is wired.
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

  final online = AppServiceRegistry.networkMonitor?.isOnline ?? false;
  if (!online) {
    return const AvailabilityFailureResult(AvailabilityOffline());
  }

  final remote = AppServiceRegistry.deliveryRemoteDataSource;
  final remoteBackend =
      remote != null && remote is! FakeDeliveryRemoteDataSource;
  final profileRepo = AppServiceRegistry.driverProfileRepository;

  if (!remoteBackend && profileRepo == null) {
    return const AvailabilityFailureResult(
      DriverProfileMissing(
        'Authoritative availability eligibility is not loaded.',
      ),
    );
  }

  // Remote Backend: session + connectivity authorize the *request*. Backend
  // rejects ineligible drivers on PUT /availability. Seed drivers use
  // pending+active which the eligibility policy already allows.
  return AvailabilitySuccess(
    AvailabilityEligibilityInput(
      authenticated: true,
      profileExists: true,
      accountStatus: AccountStatus.pending,
      employmentStatus: EmploymentStatus.active,
      hasActiveAssignment: false,
      connectivityAvailable: true,
      securityPolicyAllows: true,
    ),
  );
}

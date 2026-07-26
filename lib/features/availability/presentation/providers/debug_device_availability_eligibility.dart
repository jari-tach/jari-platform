import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/services/app_service_registry.dart';
import '../../../delivery/data/fake/fake_delivery_remote_data_source.dart';
import '../../../profile/domain/entities/driver_status.dart';
import '../../domain/entities/availability_eligibility_input.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/failures/availability_failure.dart';
import 'availability_eligibility_reader.dart';

/// DEVELOPMENT / DEBUG ONLY — device-testing eligibility bootstrap.
///
/// Allows an authenticated trial driver to request `available` when:
/// - [kDebugMode] is true
/// - [AppConfig.isProduction] is false
/// - Fake delivery remote is the active offer source
///
/// Never used in Release/Production. Production keeps
/// [readAvailabilityEligibility] default-deny until Backend eligibility exists.
AvailabilityResult<AvailabilityEligibilityInput>
readDebugDeviceAvailabilityEligibility(Ref ref, String driverId) {
  if (!kDebugMode || AppConfig.isProduction) {
    return readAvailabilityEligibility(ref, driverId);
  }

  if (!AppServiceRegistry.isInitialized) {
    return const AvailabilityFailureResult(
      DriverProfileMissing(
        'Authoritative availability eligibility is not available.',
      ),
    );
  }

  final remote = AppServiceRegistry.deliveryRemoteDataSource;
  if (remote is! FakeDeliveryRemoteDataSource) {
    // No Fake offer source → keep deny-safe production reader.
    return readAvailabilityEligibility(ref, driverId);
  }

  final normalizedId = driverId.trim();
  if (normalizedId.isEmpty) {
    return const AvailabilityFailureResult(AvailabilityUnauthenticated());
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
  final hasAssignment =
      AppServiceRegistry.getActiveDelivery != null &&
      // Synchronous presence unknown here; controller also checks busy.
      // Prefer false; accept path uses delivery state for assignment conflict.
      false;

  AppServiceRegistry.logger.info(
    'DEV-ONLY: Fake-trial availability eligibility granted for device testing',
  );

  return AvailabilitySuccess(
    AvailabilityEligibilityInput(
      authenticated: true,
      profileExists: true,
      // Trial Fake profile synthesizes pending+active — allowed by policy.
      accountStatus: AccountStatus.pending,
      employmentStatus: EmploymentStatus.active,
      hasActiveAssignment: hasAssignment,
      connectivityAvailable: online,
      securityPolicyAllows: true,
    ),
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/services/app_service_registry.dart';
import '../../../delivery/data/fake/fake_delivery_remote_data_source.dart';
import '../../domain/entities/authoritative_availability_update.dart';
import '../../domain/entities/availability_status.dart';
import '../../domain/repositories/driver_availability_repository.dart';
import '../controllers/availability_controller.dart';
import '../controllers/availability_controller_state.dart';
import 'availability_eligibility_reader.dart';
import 'debug_device_availability_eligibility.dart';

DriverAvailabilityRepository? _readAvailabilityRepository(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.driverAvailabilityRepository
    : null;

/// DEV-ONLY: builds Fake-trial system confirmation update.
///
/// Returns the update for [AvailabilityController] to apply on itself.
/// Must not call [availabilityControllerProvider] (self-dependency crash).
Future<AuthoritativeAvailabilityUpdate?> _debugConfirmTrialAvailable(
  Ref ref,
  String driverId,
) async {
  if (!kDebugMode || AppConfig.isProduction) return null;
  if (!AppServiceRegistry.isInitialized) return null;
  if (AppServiceRegistry.deliveryRemoteDataSource
      is! FakeDeliveryRemoteDataSource) {
    return null;
  }

  AppServiceRegistry.logger.info(
    'DEV-ONLY: applying Fake-trial availability confirmation for device testing',
  );

  return AuthoritativeAvailabilityUpdate(
    driverId: driverId,
    status: AvailabilityStatus.available,
    source: AvailabilitySource.system,
    confirmedAt: DateTime.now().toUtc(),
    reason: 'dev.fake_trial_confirm',
  );
}

final availabilityControllerProvider =
    NotifierProvider<AvailabilityController, AvailabilityControllerState>(
      () => AvailabilityController(
        repositoryReader: _readAvailabilityRepository,
        eligibilityReader: (kDebugMode && !AppConfig.isProduction)
            ? readDebugDeviceAvailabilityEligibility
            : readAvailabilityEligibility,
        debugTrialConfirmer: (kDebugMode && !AppConfig.isProduction)
            ? _debugConfirmTrialAvailable
            : null,
      ),
    );

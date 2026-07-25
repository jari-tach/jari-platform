import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../domain/repositories/driver_availability_repository.dart';
import '../controllers/availability_controller.dart';
import '../controllers/availability_controller_state.dart';
import 'availability_eligibility_reader.dart';

DriverAvailabilityRepository? _readAvailabilityRepository(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.driverAvailabilityRepository
    : null;

final availabilityControllerProvider =
    NotifierProvider<AvailabilityController, AvailabilityControllerState>(
      () => AvailabilityController(
        repositoryReader: _readAvailabilityRepository,
        eligibilityReader: readAvailabilityEligibility,
      ),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_controller_state.dart';

DriverProfileRepository? _readDriverProfileRepository(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.driverProfileRepository
    : null;

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileControllerState>(
      () => ProfileController(repositoryReader: _readDriverProfileRepository),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../application/realtime_coordinator.dart';
import '../controllers/realtime_controller.dart';
import '../state/realtime_controller_state.dart';

RealtimeCoordinator? _readCoordinator(Ref ref) {
  if (!AppServiceRegistry.isInitialized) return null;
  return AppServiceRegistry.realtimeCoordinator;
}

final realtimeControllerProvider =
    NotifierProvider<RealtimeController, RealtimeControllerState>(
      () => RealtimeController(coordinatorReader: _readCoordinator),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

enum VehicleApprovalStatus { approved, underReview, rejected }

class VehicleViewData {
  const VehicleViewData({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.vehicleType,
    required this.approvalStatus,
  });

  final String make;
  final String model;
  final int year;
  final String color;
  final String plate;
  final String vehicleType;
  final VehicleApprovalStatus approvalStatus;

  VehicleViewData copyWith({
    String? make,
    String? model,
    int? year,
    String? color,
    String? plate,
    String? vehicleType,
    VehicleApprovalStatus? approvalStatus,
  }) {
    return VehicleViewData(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      plate: plate ?? this.plate,
      vehicleType: vehicleType ?? this.vehicleType,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}

abstract interface class VehicleRepository {
  Future<VehicleViewData?> load();
  Future<VehicleViewData> save(VehicleViewData vehicle);
}

enum FakeVehicleMode { seeded, empty, error, offline }

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository({
    this.mode = FakeVehicleMode.seeded,
    this.failSave = false,
    this.latency = Duration.zero,
    VehicleViewData? seed,
  }) : _vehicle = seed ?? seededVehicle;

  static const seededVehicle = VehicleViewData(
    make: 'Toyota',
    model: 'Camry',
    year: 2024,
    color: 'White',
    plate: 'ABC 4821',
    vehicleType: 'Sedan',
    approvalStatus: VehicleApprovalStatus.approved,
  );

  final FakeVehicleMode mode;
  final bool failSave;
  final Duration latency;
  VehicleViewData _vehicle;

  @override
  Future<VehicleViewData?> load() async {
    await Future<void>.delayed(latency);
    return switch (mode) {
      FakeVehicleMode.seeded => _vehicle,
      FakeVehicleMode.empty => null,
      FakeVehicleMode.error => throw const VehicleRepositoryException(),
      FakeVehicleMode.offline => throw const VehicleOfflineException(),
    };
  }

  @override
  Future<VehicleViewData> save(VehicleViewData vehicle) async {
    await Future<void>.delayed(latency);
    if (mode == FakeVehicleMode.offline) {
      throw const VehicleOfflineException();
    }
    if (failSave || mode == FakeVehicleMode.error) {
      throw const VehicleRepositoryException();
    }
    _vehicle = vehicle;
    return vehicle;
  }
}

class VehicleRepositoryException implements Exception {
  const VehicleRepositoryException();
}

class VehicleOfflineException implements Exception {
  const VehicleOfflineException();
}

enum VehicleViewStatus {
  loading,
  loaded,
  empty,
  error,
  editing,
  saving,
  saveSuccess,
  validationError,
  offline,
}

class VehicleState {
  const VehicleState({this.status = VehicleViewStatus.loading, this.vehicle});

  final VehicleViewStatus status;
  final VehicleViewData? vehicle;
}

final vehicleRepositoryProvider = Provider<VehicleRepository?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // Widget tests may run before AppConfig initialization.
  }
  return FakeVehicleRepository();
});

class VehicleController extends Notifier<VehicleState> {
  @override
  VehicleState build() {
    Future.microtask(load);
    return const VehicleState();
  }

  VehicleRepository? get _repository => ref.read(vehicleRepositoryProvider);

  Future<void> load() async {
    state = VehicleState(
      status: VehicleViewStatus.loading,
      vehicle: state.vehicle,
    );
    final repository = _repository;
    if (repository == null) {
      state = const VehicleState(status: VehicleViewStatus.error);
      return;
    }
    try {
      final vehicle = await repository.load();
      if (!ref.mounted) return;
      state = VehicleState(
        status: vehicle == null
            ? VehicleViewStatus.empty
            : VehicleViewStatus.loaded,
        vehicle: vehicle,
      );
    } on VehicleOfflineException {
      if (ref.mounted) {
        state = VehicleState(
          status: VehicleViewStatus.offline,
          vehicle: state.vehicle,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = VehicleState(
          status: VehicleViewStatus.error,
          vehicle: state.vehicle,
        );
      }
    }
  }

  void startEditing() {
    state = VehicleState(
      status: VehicleViewStatus.editing,
      vehicle: state.vehicle,
    );
  }

  Future<void> save({
    required String make,
    required String model,
    required String year,
    required String color,
    required String plate,
    required String vehicleType,
  }) async {
    final parsedYear = int.tryParse(year.trim());
    if (make.trim().isEmpty ||
        model.trim().isEmpty ||
        color.trim().isEmpty ||
        plate.trim().length < 4 ||
        vehicleType.trim().isEmpty ||
        parsedYear == null ||
        parsedYear < 1980 ||
        parsedYear > 2100) {
      state = VehicleState(
        status: VehicleViewStatus.validationError,
        vehicle: state.vehicle,
      );
      return;
    }

    final repository = _repository;
    if (repository == null) {
      state = VehicleState(
        status: VehicleViewStatus.error,
        vehicle: state.vehicle,
      );
      return;
    }
    state = VehicleState(
      status: VehicleViewStatus.saving,
      vehicle: state.vehicle,
    );
    final updated = VehicleViewData(
      make: make.trim(),
      model: model.trim(),
      year: parsedYear,
      color: color.trim(),
      plate: plate.trim(),
      vehicleType: vehicleType.trim(),
      approvalStatus:
          state.vehicle?.approvalStatus ?? VehicleApprovalStatus.underReview,
    );
    try {
      final saved = await repository.save(updated);
      if (ref.mounted) {
        state = VehicleState(
          status: VehicleViewStatus.saveSuccess,
          vehicle: saved,
        );
      }
    } on VehicleOfflineException {
      if (ref.mounted) {
        state = VehicleState(
          status: VehicleViewStatus.offline,
          vehicle: state.vehicle,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = VehicleState(
          status: VehicleViewStatus.error,
          vehicle: state.vehicle,
        );
      }
    }
  }
}

final vehicleControllerProvider =
    NotifierProvider<VehicleController, VehicleState>(VehicleController.new);

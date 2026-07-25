import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../../auth/domain/entities/driver_session.dart';
import '../../../auth/domain/repositories/authentication_repository.dart';
import '../../../driver/data/datasources/local/driver_database.dart'
    hide DriverProfile;
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/driver_profile_provenance.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/entities/profile_error.dart';
import '../../domain/policies/fake_profile_synthesis_policy.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import '../mappers/driver_profile_local_mapper.dart';

/// PHASE 2.3 fake/local profile repository.
///
/// Trial synthesis is allowed only when [FakeProfileSynthesisPolicy] permits
/// it. Production/Release cache misses throw [ProfileNotFoundError].
/// Hard [kReleaseMode] check cannot be disabled by injected env callbacks.
class FakeDriverProfileRepository implements DriverProfileRepository {
  FakeDriverProfileRepository({
    required AuthenticationRepository authenticationRepository,
    required this._logger,
    this._database,
    this._isProductionEnvironment = _defaultIsProductionEnvironment,
  }) : _auth = authenticationRepository;

  static bool _defaultIsProductionEnvironment() => AppConfig.isProduction;

  final AuthenticationRepository _auth;
  final LoggerService _logger;
  final DriverDatabase? _database;
  final bool Function() _isProductionEnvironment;

  DriverProfile? _memoryCache;

  /// Hard Release first, then policy. Injected production flag never clears
  /// a Release deny.
  bool get _maySynthesizeTrialProfile {
    if (kReleaseMode) return false;
    return FakeProfileSynthesisPolicy.evaluate(
      isReleaseMode: false,
      isProductionEnvironment: _isProductionEnvironment(),
    ).allowed;
  }

  @override
  Future<DriverProfile> getCurrentProfile() async {
    final session = _requireValidSession();

    final cached = _memoryCache;
    if (cached != null && cached.driverId == session.driverId) {
      return cached;
    }

    final local = await _readLocal(session.driverId);
    if (local != null) {
      _memoryCache = local;
      return local;
    }

    if (!_maySynthesizeTrialProfile) {
      _logger.warning(
        'FakeDriverProfileRepository: profile missing; synthesis blocked '
        '(${FakeProfileSynthesisPolicy.policyVersion})',
      );
      throw const ProfileNotFoundError();
    }

    final synthesized = _synthesizeTrialProfile(session);
    await _writeLocal(synthesized);
    _memoryCache = synthesized;
    _logger.info(
      'FakeDriverProfileRepository: synthesized trial profile for driver',
    );
    return synthesized;
  }

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) async {
    if (!update.hasChanges) {
      return getCurrentProfile();
    }

    final current = await getCurrentProfile();
    final next = current.applyClientUpdate(update);

    if (next.driverId != current.driverId ||
        next.businessId != current.businessId ||
        next.branchId != current.branchId ||
        next.phoneNumber != current.phoneNumber ||
        next.accountStatus != current.accountStatus ||
        next.employmentStatus != current.employmentStatus ||
        next.createdAt != current.createdAt ||
        next.vehicleType != current.vehicleType ||
        next.vehiclePlate != current.vehiclePlate ||
        next.provenance != current.provenance) {
      throw const ProfileSovereignFieldMutationError();
    }

    await _writeLocal(next);
    _memoryCache = next;
    return next;
  }

  DriverSession _requireValidSession() {
    final session = _auth.currentSession;
    if (session == null) {
      throw const ProfileUnauthenticatedError();
    }
    if (session.isExpired) {
      throw const ProfileSessionExpiredError();
    }
    return session;
  }

  Future<DriverProfile?> _readLocal(String driverId) async {
    final db = _database;
    if (db == null) return null;
    try {
      final row = await db.getDriverByDriverId(driverId);
      if (row == null) return null;
      return DriverProfileLocalMapper.fromRow(row);
    } catch (error, stackTrace) {
      _logger.error(
        'FakeDriverProfileRepository: local read failed',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<void> _writeLocal(DriverProfile profile) async {
    final db = _database;
    if (db == null) return;
    try {
      await db.upsertDriverProfile(
        DriverProfileLocalMapper.toCompanion(profile),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'FakeDriverProfileRepository: local write failed',
        error,
        stackTrace,
      );
    }
  }

  static DriverProfile _synthesizeTrialProfile(DriverSession session) {
    final now = DateTime.now();
    final suffix = session.phoneNumber.length >= 4
        ? session.phoneNumber.substring(session.phoneNumber.length - 4)
        : session.phoneNumber;
    return DriverProfile(
      driverId: session.driverId,
      businessId: null,
      branchId: null,
      fullName: 'Driver $suffix',
      phoneNumber: session.phoneNumber,
      email: null,
      profileImageUrl: null,
      accountStatus: AccountStatus.pending,
      employmentStatus: EmploymentStatus.active,
      vehicleType: 'motorcycle',
      vehiclePlate: null,
      createdAt: now,
      updatedAt: now,
      provenance: DriverProfileProvenance.trialSynthetic,
    );
  }
}

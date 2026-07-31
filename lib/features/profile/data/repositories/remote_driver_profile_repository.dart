import '../../../../core/network/idempotency_key_factory.dart';
import '../../../../core/network/remote_error_classification.dart';
import '../../../../core/network/remote_error_mapper.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/profile_error.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import '../remote/driver_profile_remote_data_source.dart';

final class RemoteDriverProfileRepository implements DriverProfileRepository {
  RemoteDriverProfileRepository({
    required this._remote,
    IdempotencyKeyFactory? idempotencyKeyFactory,
    RemoteErrorMapper? errorMapper,
  }) : _idempotencyKeys = idempotencyKeyFactory ?? IdempotencyKeyFactory(),
       _errorMapper = errorMapper ?? const RemoteErrorMapper();

  final DriverProfileRemoteDataSource _remote;
  final IdempotencyKeyFactory _idempotencyKeys;
  final RemoteErrorMapper _errorMapper;

  DriverComplianceSnapshot? _lastCompliance;

  DriverComplianceSnapshot? get lastCompliance => _lastCompliance;

  Future<DriverComplianceSnapshot> getCompliance() async {
    try {
      final wire = await _remote.getCompliance();
      final snapshot = DriverComplianceSnapshot(
        overallStatus: wire.overallStatus,
        blockingReasons: wire.blockingReasons,
        lastEvaluatedAt: wire.lastEvaluatedAt,
      );
      _lastCompliance = snapshot;
      return snapshot;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<DriverProfile> getCurrentProfile() async {
    try {
      return (await _remote.getMe()).toDomain();
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) async {
    if (!update.hasChanges) {
      return getCurrentProfile();
    }
    try {
      return (await _remote.patchMe(
        idempotencyKey: _idempotencyKeys.next(),
        displayName: update.fullName,
      )).toDomain();
    } catch (e) {
      throw _mapError(e);
    }
  }

  ProfileError _mapError(Object error) {
    if (error is ProfileError) return error;
    if (error is FormatException) {
      return const ProfileInvalidDataError();
    }
    final classification = _errorMapper.classify(error);
    switch (classification) {
      case RemoteErrorClassification.unauthorized:
      case RemoteErrorClassification.sessionExpired:
        return const ProfileSessionExpiredError();
      case RemoteErrorClassification.forbidden:
        return const ProfileForbiddenError();
      case RemoteErrorClassification.notFound:
        return const ProfileNotFoundError();
      case RemoteErrorClassification.validation:
      case RemoteErrorClassification.contractViolation:
        return const ProfileInvalidDataError();
      case RemoteErrorClassification.networkUnavailable:
      case RemoteErrorClassification.requestTimeout:
      case RemoteErrorClassification.serverUnavailable:
      case RemoteErrorClassification.conflict:
      case RemoteErrorClassification.rateLimited:
      case RemoteErrorClassification.unknown:
        return const ProfileUnexpectedError();
    }
  }
}

/// Lightweight compliance view for STEP 5C-2 (not a full domain entity yet).
final class DriverComplianceSnapshot {
  const DriverComplianceSnapshot({
    required this.overallStatus,
    required this.blockingReasons,
    required this.lastEvaluatedAt,
  });

  final String overallStatus;
  final List<String> blockingReasons;
  final DateTime lastEvaluatedAt;
}

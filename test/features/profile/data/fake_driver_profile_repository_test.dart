import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/domain/entities/authentication_status.dart';
import 'package:saeq_driver/features/auth/domain/entities/driver_session.dart';
import 'package:saeq_driver/features/auth/domain/repositories/authentication_repository.dart';
import 'package:saeq_driver/features/profile/data/repositories/fake_driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile_provenance.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';

class _SilentLogger implements LoggerService {
  @override
  LogLevel level = LogLevel.debug;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}
}

class _MemoryAuth implements AuthenticationRepository {
  DriverSession? session;

  @override
  DriverSession? get currentSession => session;

  @override
  Stream<AuthenticationStatus> get authStateChanges => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<DriverSession?> restoreSession() async => session;

  @override
  Future<DriverSession> signIn(String phoneNumber) async {
    throw const UnexpectedAuthError();
  }

  @override
  Future<void> signOut() async {
    session = null;
  }
}

void main() {
  late _MemoryAuth auth;

  setUp(() {
    auth = _MemoryAuth();
  });

  DriverSession validSession() => DriverSession(
    driverId: 'd1',
    phoneNumber: '0512345678',
    sessionToken: 'token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  test('getCurrentProfile throws when unauthenticated', () async {
    final repository = FakeDriverProfileRepository(
      authenticationRepository: auth,
      logger: _SilentLogger(),
    );
    expect(
      () => repository.getCurrentProfile(),
      throwsA(isA<ProfileUnauthenticatedError>()),
    );
  });

  test('getCurrentProfile throws when session expired', () async {
    final repository = FakeDriverProfileRepository(
      authenticationRepository: auth,
      logger: _SilentLogger(),
    );
    auth.session = DriverSession(
      driverId: 'd1',
      phoneNumber: '0512345678',
      sessionToken: 'token',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(
      () => repository.getCurrentProfile(),
      throwsA(isA<ProfileSessionExpiredError>()),
    );
  });

  test('synthesis succeeds only in approved non-production mode', () async {
    final repository = FakeDriverProfileRepository(
      authenticationRepository: auth,
      logger: _SilentLogger(),
      isProductionEnvironment: () => false,
    );
    auth.session = validSession();

    final profile = await repository.getCurrentProfile();
    expect(profile.driverId, 'd1');
    expect(profile.businessId, isNull);
    expect(profile.branchId, isNull);
    expect(profile.provenance, DriverProfileProvenance.trialSynthetic);
    expect(profile.isTrialSynthetic, isTrue);
  });

  test(
    'production cache miss returns ProfileNotFoundError (direct call)',
    () async {
      final repository = FakeDriverProfileRepository(
        authenticationRepository: auth,
        logger: _SilentLogger(),
        isProductionEnvironment: () => true,
      );
      auth.session = validSession();

      expect(
        () => repository.getCurrentProfile(),
        throwsA(isA<ProfileNotFoundError>()),
      );
    },
  );

  test(
    'updateCurrentProfile keeps sovereign and vehicle fields unchanged',
    () async {
      final repository = FakeDriverProfileRepository(
        authenticationRepository: auth,
        logger: _SilentLogger(),
        isProductionEnvironment: () => false,
      );
      auth.session = validSession();

      final original = await repository.getCurrentProfile();
      final updated = await repository.updateCurrentProfile(
        const DriverProfileUpdate(fullName: 'Updated Driver'),
      );
      expect(updated.fullName, 'Updated Driver');
      expect(updated.driverId, original.driverId);
      expect(updated.businessId, original.businessId);
      expect(updated.branchId, original.branchId);
      expect(updated.phoneNumber, original.phoneNumber);
      expect(updated.accountStatus, original.accountStatus);
      expect(updated.employmentStatus, original.employmentStatus);
      expect(updated.createdAt, original.createdAt);
      expect(updated.vehicleType, original.vehicleType);
      expect(updated.vehiclePlate, original.vehiclePlate);
      expect(updated.provenance, original.provenance);
    },
  );
}

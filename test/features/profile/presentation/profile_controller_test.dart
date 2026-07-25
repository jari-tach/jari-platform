import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller_state.dart';
import 'package:saeq_driver/features/profile/presentation/providers/profile_providers.dart';

class _FakeRepo implements DriverProfileRepository {
  _FakeRepo(this._result);

  final Object _result;

  @override
  Future<DriverProfile> getCurrentProfile() async {
    final value = _result;
    if (value is ProfileError) throw value;
    if (value is DriverProfile) return value;
    throw const ProfileUnexpectedError();
  }

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) {
    return getCurrentProfile();
  }
}

DriverProfile _sampleProfile() {
  final now = DateTime.utc(2026, 7, 25);
  return DriverProfile(
    driverId: 'd1',
    fullName: 'Driver One',
    phoneNumber: '0512345678',
    accountStatus: AccountStatus.pending,
    employmentStatus: EmploymentStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('ProfileController loads success state', () async {
    final container = ProviderContainer(
      overrides: [
        profileControllerProvider.overrideWith(
          () => ProfileController(
            repositoryReader: (_) => _FakeRepo(_sampleProfile()),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(profileControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(profileControllerProvider);
    expect(state.status, ProfileViewStatus.success);
    expect(state.profile?.fullName, 'Driver One');
  });

  test('ProfileController maps session expired', () async {
    final container = ProviderContainer(
      overrides: [
        profileControllerProvider.overrideWith(
          () => ProfileController(
            repositoryReader: (_) =>
                _FakeRepo(const ProfileSessionExpiredError()),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(profileControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      container.read(profileControllerProvider).status,
      ProfileViewStatus.sessionExpired,
    );
  });

  test('ProfileController maps not found to empty', () async {
    final container = ProviderContainer(
      overrides: [
        profileControllerProvider.overrideWith(
          () => ProfileController(
            repositoryReader: (_) => _FakeRepo(const ProfileNotFoundError()),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(profileControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      container.read(profileControllerProvider).status,
      ProfileViewStatus.empty,
    );
  });
}

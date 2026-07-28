import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller_state.dart';
import 'package:saeq_driver/features/profile/presentation/providers/profile_providers.dart';

class _UpdatingRepo implements DriverProfileRepository {
  _UpdatingRepo({
    required this.profile,
    this.failUpdate = false,
    this.updateDelay = Duration.zero,
  });

  DriverProfile profile;
  final bool failUpdate;
  final Duration updateDelay;
  int updateCalls = 0;

  @override
  Future<DriverProfile> getCurrentProfile() async => profile;

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) async {
    updateCalls += 1;
    await Future<void>.delayed(updateDelay);
    if (failUpdate) throw const ProfileUnexpectedError();
    profile = profile.applyClientUpdate(update);
    return profile;
  }
}

DriverProfile _sampleProfile({String fullName = 'Driver One'}) {
  final now = DateTime.utc(2026, 7, 25);
  return DriverProfile(
    driverId: 'd1',
    fullName: fullName,
    phoneNumber: '0512345678',
    email: 'old@example.com',
    accountStatus: AccountStatus.pending,
    employmentStatus: EmploymentStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('ProfileController updateProfile success updates state', () async {
    final repo = _UpdatingRepo(profile: _sampleProfile());
    final container = ProviderContainer(
      overrides: [
        profileControllerProvider.overrideWith(
          () => ProfileController(repositoryReader: (_) => repo),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(profileControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final success = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(const DriverProfileUpdate(fullName: 'Updated Name'));

    expect(success, isTrue);
    expect(
      container.read(profileControllerProvider).profile?.fullName,
      'Updated Name',
    );
    expect(repo.updateCalls, 1);
  });

  test(
    'ProfileController updateProfile failure preserves prior profile',
    () async {
      final repo = _UpdatingRepo(profile: _sampleProfile(), failUpdate: true);
      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(repositoryReader: (_) => repo),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(profileControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final success = await container
          .read(profileControllerProvider.notifier)
          .updateProfile(const DriverProfileUpdate(fullName: 'Broken Update'));

      expect(success, isFalse);
      expect(
        container.read(profileControllerProvider).profile?.fullName,
        'Driver One',
      );
      expect(
        container.read(profileControllerProvider).status,
        ProfileViewStatus.success,
      );
    },
  );

  test(
    'ProfileController updateProfile ignores duplicate concurrent calls',
    () async {
      final repo = _UpdatingRepo(
        profile: _sampleProfile(),
        updateDelay: const Duration(milliseconds: 100),
      );
      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(repositoryReader: (_) => repo),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(profileControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final first = container
          .read(profileControllerProvider.notifier)
          .updateProfile(const DriverProfileUpdate(fullName: 'First'));
      final second = container
          .read(profileControllerProvider.notifier)
          .updateProfile(const DriverProfileUpdate(fullName: 'Second'));

      await first;
      await second;

      expect(repo.updateCalls, 1);
    },
  );
}

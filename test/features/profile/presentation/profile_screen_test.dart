import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller.dart';
import 'package:saeq_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saeq_driver/features/profile/presentation/screens/profile_screen.dart';

class _Repo implements DriverProfileRepository {
  _Repo(this.profile);

  final DriverProfile? profile;

  @override
  Future<DriverProfile> getCurrentProfile() async {
    final value = profile;
    if (value == null) throw const ProfileNotFoundError();
    return value;
  }

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) {
    return getCurrentProfile();
  }
}

void main() {
  testWidgets('ProfileScreen shows driver name when loaded', (tester) async {
    final now = DateTime.utc(2026, 7, 25);
    final profile = DriverProfile(
      driverId: 'd1',
      fullName: 'Driver One',
      phoneNumber: '0512345678',
      accountStatus: AccountStatus.pending,
      employmentStatus: EmploymentStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(repositoryReader: (_) => _Repo(profile)),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Driver One'), findsOneWidget);
    expect(find.text('0512345678'), findsOneWidget);
    expect(find.text('Not assigned yet'), findsWidgets);
  });

  testWidgets('ProfileScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(repositoryReader: (_) => _Repo(null)),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No profile yet'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

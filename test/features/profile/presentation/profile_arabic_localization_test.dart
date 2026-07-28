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
  _Repo({this.profile, this.error});

  final DriverProfile? profile;
  final ProfileError? error;

  @override
  Future<DriverProfile> getCurrentProfile() async {
    final failure = error;
    if (failure != null) throw failure;
    final value = profile;
    if (value == null) throw const ProfileNotFoundError();
    return value;
  }

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) {
    return getCurrentProfile();
  }
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required DriverProfileRepository repo,
  required Locale locale,
  double textScale = 1.0,
  Size surfaceSize = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileControllerProvider.overrideWith(
          () => ProfileController(repositoryReader: (_) => repo),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          locale: locale,
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
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  final now = DateTime.utc(2026, 7, 25);

  DriverProfile readyProfile() => DriverProfile(
    driverId: 'd1',
    fullName: 'أحمد السائق',
    phoneNumber: '0512345678',
    accountStatus: AccountStatus.verified,
    employmentStatus: EmploymentStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  group('ProfileScreen localization', () {
    testWidgets('Arabic ready state shows Arabic labels only', (tester) async {
      await _pumpProfile(
        tester,
        repo: _Repo(profile: readyProfile()),
        locale: const Locale('ar'),
      );

      expect(find.text('ملف السائق'), findsOneWidget);
      expect(find.text('أحمد السائق'), findsOneWidget);
      // Phone is masked for display (last 2 digits only).
      expect(find.text('********78'), findsOneWidget);
      expect(find.text('0512345678'), findsNothing);
      expect(find.text('حالة الحساب'), findsOneWidget);
      expect(find.text('موثَّق'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('غير معيّن بعد'), findsWidgets);
      // Success state no longer shows a redundant retry action.
      expect(find.text('إعادة المحاولة'), findsNothing);
      expect(find.text('Account status'), findsNothing);
      expect(find.text('Verified'), findsNothing);
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('Arabic missing profile state', (tester) async {
      await _pumpProfile(tester, repo: _Repo(), locale: const Locale('ar'));

      expect(find.text('لا يوجد ملف بعد'), findsOneWidget);
      expect(find.textContaining('تعذر العثور على ملف السائق'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('No profile yet'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('Arabic failure state maps typed error safely', (tester) async {
      await _pumpProfile(
        tester,
        repo: _Repo(error: const ProfileForbiddenError()),
        locale: const Locale('ar'),
      );

      expect(find.text('تعذر تحميل الملف'), findsOneWidget);
      expect(find.textContaining('ليس لديك صلاحية'), findsOneWidget);
      expect(find.text('Could not load profile'), findsNothing);
      expect(find.textContaining('ProfileForbidden'), findsNothing);
    });

    testWidgets('English ready state regression', (tester) async {
      await _pumpProfile(
        tester,
        repo: _Repo(
          profile: DriverProfile(
            driverId: 'd1',
            fullName: 'Driver One',
            phoneNumber: '0512345678',
            accountStatus: AccountStatus.pending,
            employmentStatus: EmploymentStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        locale: const Locale('en', 'US'),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Driver One'), findsOneWidget);
      expect(find.text('Account status'), findsOneWidget);
      expect(find.text('Pending verification'), findsOneWidget);
      expect(find.text('ملف السائق'), findsNothing);
      expect(find.text('حالة الحساب'), findsNothing);
    });

    testWidgets('Arabic locale drives RTL on profile', (tester) async {
      await _pumpProfile(
        tester,
        repo: _Repo(profile: readyProfile()),
        locale: const Locale('ar'),
      );
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality).first,
        ),
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('Arabic large text has no overflow on profile', (tester) async {
      await _pumpProfile(
        tester,
        repo: _Repo(profile: readyProfile()),
        locale: const Locale('ar'),
        textScale: 1.6,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('ملف السائق'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller.dart';
import 'package:saeq_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saeq_driver/features/profile/presentation/screens/profile_edit_screen.dart';

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
  DriverProfileUpdate? lastUpdate;

  @override
  Future<DriverProfile> getCurrentProfile() async => profile;

  @override
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update) async {
    updateCalls += 1;
    lastUpdate = update;
    await Future<void>.delayed(updateDelay);
    if (failUpdate) throw const ProfileUnexpectedError();
    profile = profile.applyClientUpdate(update);
    return profile;
  }
}

DriverProfile _sampleProfile({
  String fullName = 'Driver One',
  String? email = 'old@example.com',
}) {
  final now = DateTime.utc(2026, 7, 25);
  return DriverProfile(
    driverId: 'd1',
    fullName: fullName,
    phoneNumber: '0512345678',
    email: email,
    accountStatus: AccountStatus.pending,
    employmentStatus: EmploymentStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

Future<ProviderContainer> _pumpProfileEdit(
  WidgetTester tester, {
  required _UpdatingRepo repo,
  ProviderContainer? container,
  Locale locale = const Locale('en', 'US'),
  Widget? home,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  final scopeContainer =
      container ??
      ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(repositoryReader: (_) => repo),
          ),
        ],
      );
  if (container == null) {
    addTearDown(scopeContainer.dispose);
  }

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => home ?? const ProfileEditScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scopeContainer,
      child: MaterialApp.router(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return scopeContainer;
}

Finder get _fullNameField => find.byType(TextFormField).at(0);
Finder get _emailField => find.byType(TextFormField).at(1);
Finder get _saveButton => find.byKey(ProfileEditScreen.saveKey);

void main() {
  group('ProfileEditScreen widget', () {
    testWidgets('seeds full name and email from loaded profile', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      final fullName = tester.widget<TextFormField>(_fullNameField);
      final email = tester.widget<TextFormField>(_emailField);
      expect(fullName.controller?.text, 'Driver One');
      expect(email.controller?.text, 'old@example.com');
    });

    testWidgets('empty full name shows validation error and blocks save', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, '');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(repo.updateCalls, 0);
    });

    testWidgets('empty optional email is accepted on save', (tester) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Renamed Driver');
      await tester.enterText(_emailField, '');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(repo.updateCalls, 1);
      expect(repo.lastUpdate?.email, isNull);
    });

    testWidgets('valid email is accepted on save', (tester) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Renamed Driver');
      await tester.enterText(_emailField, 'new@example.com');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(repo.updateCalls, 1);
      expect(repo.lastUpdate?.email, 'new@example.com');
    });

    testWidgets('whitespace-trimmed valid email is normalized on save', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Renamed Driver');
      await tester.enterText(_emailField, '  trimmed@example.com  ');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.updateCalls, 1);
      expect(repo.lastUpdate?.email, 'trimmed@example.com');
    });

    testWidgets('missing @ shows validation error and blocks save', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Renamed Driver');
      await tester.enterText(_emailField, 'not-an-email');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(repo.updateCalls, 0);
    });

    testWidgets('missing domain shows validation error and blocks save', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Renamed Driver');
      await tester.enterText(_emailField, 'user@');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(repo.updateCalls, 0);
    });

    testWidgets('malformed domain shows validation error and blocks save', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Renamed Driver');
      await tester.enterText(_emailField, 'user@domain');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(repo.updateCalls, 0);
    });

    testWidgets('invalid email shows Arabic validation error', (tester) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      await _pumpProfileEdit(tester, repo: repo, locale: const Locale('ar'));

      await tester.enterText(_fullNameField, 'سائق');
      await tester.enterText(_emailField, 'bad-email');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('أدخل بريداً إلكترونياً صالحاً.'), findsOneWidget);
      expect(repo.updateCalls, 0);
    });

    testWidgets('save success shows snackbar and updates controller profile', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      final container = await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Updated Name');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Profile updated.'), findsOneWidget);
      expect(
        container.read(profileControllerProvider).profile?.fullName,
        'Updated Name',
      );
      expect(find.byType(ProfileEditScreen), findsOneWidget);
    });

    testWidgets('save failure shows snackbar and preserves prior profile', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile(), failUpdate: true);
      final container = await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Broken Update');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Could not update profile. Please try again.'),
        findsOneWidget,
      );
      expect(
        container.read(profileControllerProvider).profile?.fullName,
        'Driver One',
      );
    });

    testWidgets('duplicate save taps issue only one repository update', (
      tester,
    ) async {
      final repo = _UpdatingRepo(
        profile: _sampleProfile(),
        updateDelay: const Duration(milliseconds: 200),
      );
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Concurrent Save');
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(repo.updateCalls, 1);
    });

    testWidgets('save button shows loading state while updating', (
      tester,
    ) async {
      final repo = _UpdatingRepo(
        profile: _sampleProfile(),
        updateDelay: const Duration(milliseconds: 200),
      );
      await _pumpProfileEdit(tester, repo: repo);

      await tester.enterText(_fullNameField, 'Loading Test');
      await tester.tap(_saveButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('AppBar back control appears on stacked edit route', (
      tester,
    ) async {
      final repo = _UpdatingRepo(profile: _sampleProfile());
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Home screen'))),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) => const ProfileEditScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(
            () => ProfileController(repositoryReader: (_) => repo),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('en', 'US'),
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      router.push('/edit');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(ProfileEditScreen).evaluate().isEmpty) break;
      }

      expect(find.text('Home screen'), findsOneWidget);
    });
  });
}

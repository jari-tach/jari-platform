import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/profile/documents/document_upload_screen.dart';
import 'package:saeq_driver/features/profile/documents/documents_feature.dart';
import 'package:saeq_driver/features/profile/documents/documents_list_screen.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller.dart';
import 'package:saeq_driver/features/profile/presentation/providers/profile_providers.dart';
import 'package:saeq_driver/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:saeq_driver/features/profile/presentation/screens/profile_screen.dart';
import 'package:saeq_driver/features/profile/vehicle/vehicle_edit_screen.dart';
import 'package:saeq_driver/features/profile/vehicle/vehicle_feature.dart';
import 'package:saeq_driver/features/profile/vehicle/vehicle_overview_screen.dart';
import 'package:saeq_driver/features/settings/presentation/screens/settings_screen.dart';
import 'package:saeq_driver/features/support/presentation/screens/support_safety_screen.dart';
import 'package:saeq_driver/features/support/presentation/screens/support_screen.dart';

class _ProfileRepo implements DriverProfileRepository {
  _ProfileRepo(this.profile);

  final DriverProfile profile;

  @override
  Future<DriverProfile> getCurrentProfile() async => profile;

  @override
  Future<DriverProfile> updateCurrentProfile(
    DriverProfileUpdate update,
  ) async => profile;
}

DriverProfile _sampleProfile() {
  final now = DateTime.utc(2026, 7, 29);
  return DriverProfile(
    driverId: 'd1',
    fullName: 'Driver One',
    phoneNumber: '0512345678',
    accountStatus: AccountStatus.verified,
    employmentStatus: EmploymentStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

Future<GoRouter> _pumpProfileRouter(
  WidgetTester tester, {
  Locale locale = const Locale('en', 'US'),
  VehicleRepository? vehicleRepository,
  DocumentsRepository? documentsRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileVehicle,
        builder: (context, state) => const VehicleOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileVehicleEdit,
        builder: (context, state) => const VehicleEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDocuments,
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDocumentsUpload,
        builder: (context, state) => const DocumentUploadScreen(),
      ),
      GoRoute(
        path: '/profile/documents/:id',
        builder: (context, state) =>
            DocumentDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.supportSafety,
        builder: (context, state) => const SupportSafetyScreen(),
      ),
    ],
    initialLocation: AppRoutes.profile,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileControllerProvider.overrideWith(
          () => ProfileController(
            repositoryReader: (_) => _ProfileRepo(_sampleProfile()),
          ),
        ),
        if (vehicleRepository != null)
          vehicleRepositoryProvider.overrideWithValue(vehicleRepository),
        if (documentsRepository != null)
          documentsRepositoryProvider.overrideWithValue(documentsRepository),
      ],
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
  await tester.pump(const Duration(milliseconds: 100));
  return router;
}

void main() {
  testWidgets('Profile navigation rows route to vehicle and documents', (
    tester,
  ) async {
    await _pumpProfileRouter(
      tester,
      vehicleRepository: FakeVehicleRepository(),
      documentsRepository: FakeDocumentsRepository(),
    );

    expect(find.byKey(ProfileScreen.vehicleRowKey), findsOneWidget);
    expect(find.byKey(ProfileScreen.documentsRowKey), findsOneWidget);

    await tester.tap(find.byKey(ProfileScreen.vehicleRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(VehicleOverviewScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ProfileScreen.documentsRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentsListScreen), findsOneWidget);
  });

  testWidgets('Profile rows route to settings support and safety', (
    tester,
  ) async {
    await _pumpProfileRouter(tester);

    await tester.tap(find.byKey(ProfileScreen.settingsRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ProfileScreen.supportRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(SupportScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ProfileScreen.safetyRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(SupportSafetyScreen), findsOneWidget);
  });

  testWidgets('Profile logout shows confirmation dialog', (tester) async {
    await _pumpProfileRouter(tester);

    await tester.tap(find.byKey(ProfileScreen.signOutRowKey));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('saeqDestructiveDialogConfirm')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('saeqDestructiveDialogCancel')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/mappers/availability_failure_messages.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/availability/presentation/widgets/driver_availability_card.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

import '../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 23);

  DriverAvailability unavailable() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.unavailable,
    source: AvailabilitySource.system,
    lastChangedAt: at,
  );

  DriverAvailability availableConfirmed() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.available,
    source: AvailabilitySource.server,
    lastChangedAt: at,
    lastConfirmedAt: at,
    pendingSync: false,
    revision: 2,
  );

  DriverAvailability busy() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.busy,
    source: AvailabilitySource.system,
    lastChangedAt: at,
    activeAssignmentId: 'asg-1',
    pendingSync: true,
  );

  AvailabilityEligibilityInput eligible() => const AvailabilityEligibilityInput(
    authenticated: true,
    profileExists: true,
    accountStatus: AccountStatus.verified,
    employmentStatus: EmploymentStatus.active,
    hasActiveAssignment: false,
    connectivityAvailable: true,
    securityPolicyAllows: true,
  );

  Future<ProviderContainer> bootArabic(
    WidgetTester tester,
    FakeDriverAvailabilityRepository fake, {
    AvailabilityEligibilityReader? eligibilityReader,
    double textScale = 1.0,
    Size surfaceSize = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final container = ProviderContainer(
      overrides: [
        availabilityControllerProvider.overrideWith(
          () => AvailabilityController(
            repositoryReader: (_) => fake,
            eligibilityReader:
                eligibilityReader ?? (_, _) => AvailabilitySuccess(eligible()),
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      fake.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: DriverAvailabilityCard(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    return container;
  }

  group('AppLocalizations availability language selection', () {
    test('English locale keeps English availability copy', () {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      expect(l10n.isArabic, isFalse);
      expect(l10n.availabilitySectionTitle, 'Availability');
      expect(l10n.availabilityActionGoAvailable, 'Start receiving requests');
      expect(
        l10n.availabilityFailureProfileMissing,
        'Driver account readiness could not be verified yet.',
      );
    });

    test('Arabic locale returns Arabic availability copy', () {
      final l10n = AppLocalizations(const Locale('ar'));
      expect(l10n.isArabic, isTrue);
      expect(l10n.availabilitySectionTitle, 'التوفر');
      expect(l10n.availabilityActionGoAvailable, 'بدء استقبال الطلبات');
      expect(l10n.availabilityActionGoUnavailable, 'إيقاف استقبال الطلبات');
      expect(
        l10n.availabilityFailureProfileMissing,
        'تعذر التحقق من جاهزية حساب السائق حاليًا.',
      );
      expect(l10n.availabilityChipConfirmed, 'مؤكَّد');
      expect(l10n.availabilityChipPending, 'بانتظار التأكيد');
      expect(l10n.availabilityChipRestored, 'مستعادة — غير مؤكَّدة');
    });

    test('unsupported locale falls back to English', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.isArabic, isFalse);
      expect(l10n.availabilitySectionTitle, 'Availability');
      expect(l10n.availabilityActionGoAvailable, 'Start receiving requests');
    });

    test('Arabic mapper messages for typed failures', () {
      final l10n = AppLocalizations(const Locale('ar', 'SA'));
      expect(
        availabilityFailureMessage(const AvailabilityUnauthenticated(), l10n),
        'انتهت الجلسة. سجّل الدخول مجددًا.',
      );
      expect(
        availabilityFailureMessage(
          const AvailabilitySecurityPolicyDenied(),
          l10n,
        ),
        'تعذر تنفيذ الطلب لأسباب تتعلق بأمان الحساب.',
      );
      expect(
        availabilityFailureMessage(const DriverProfileMissing(), l10n),
        'تعذر التحقق من جاهزية حساب السائق حاليًا.',
      );
      expect(
        availabilityFailureMessage(const AvailabilityOffline(), l10n),
        'اتصل بالإنترنت قبل تفعيل استقبال الطلبات.',
      );
      expect(
        availabilityFailureMessage(const AvailabilityUnknownFailure(), l10n),
        'حدث خطأ أثناء تحديث حالة التوفر.',
      );
    });
  });

  group('DriverAvailabilityCard Arabic rendering', () {
    testWidgets('Arabic unavailable state', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootArabic(tester, fake);
      expect(find.text('التوفر'), findsOneWidget);
      expect(find.text('غير متاح لاستقبال الطلبات'), findsOneWidget);
      expect(find.text('بدء استقبال الطلبات'), findsOneWidget);
      expect(find.text('Start receiving requests'), findsNothing);
      expect(find.text('Confirmed'), findsNothing);
      expect(find.text('مؤكَّد'), findsNothing);
    });

    testWidgets('Arabic confirmed available state', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await bootArabic(tester, fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .applyAuthoritativeUpdate(
            AuthoritativeAvailabilityUpdate(
              driverId: 'drv-1',
              status: AvailabilityStatus.available,
              source: AvailabilitySource.server,
              confirmedAt: at,
              revision: 3,
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('متاح للطلبات'), findsOneWidget);
      expect(find.text('مؤكَّد'), findsOneWidget);
      expect(find.text('بانتظار التأكيد'), findsNothing);
      expect(find.text('Confirmed'), findsNothing);
    });

    testWidgets('Arabic pending available is not confirmed', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await bootArabic(tester, fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('جارٍ تأكيد حالة التوفر'), findsOneWidget);
      expect(find.text('بانتظار التأكيد'), findsOneWidget);
      expect(find.text('مؤكَّد'), findsNothing);
      expect(find.text('Available for orders'), findsNothing);
    });

    testWidgets('Arabic restored available warning', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: availableConfirmed());
      await bootArabic(tester, fake);
      expect(
        find.text('تمت استعادة حالة سابقة — تحتاج إلى تأكيد'),
        findsOneWidget,
      );
      expect(find.text('مستعادة — غير مؤكَّدة'), findsOneWidget);
      expect(find.text('مؤكَّد'), findsNothing);
    });

    testWidgets('Arabic restored busy awaiting verification', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: busy());
      await bootArabic(tester, fake);
      expect(
        find.text('تمت استعادة حالة مشغول — بانتظار التحقق'),
        findsOneWidget,
      );
      expect(find.text('مستعادة — غير مؤكَّدة'), findsOneWidget);
      expect(find.text('asg-1'), findsNothing);
      expect(find.text('مؤكَّد'), findsNothing);
    });

    testWidgets('Arabic offline state', (tester) async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
        ),
      );
      await bootArabic(tester, fake);
      expect(find.text('بدون اتصال'), findsWidgets);
      expect(find.text('تحقق من الشبكة ثم أعد المحاولة.'), findsOneWidget);
      expect(find.text('Start receiving requests'), findsNothing);
    });

    testWidgets('Arabic loading state', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..restoreDelay = const Duration(milliseconds: 200);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final container = ProviderContainer(
        overrides: [
          availabilityControllerProvider.overrideWith(
            () => AvailabilityController(
              repositoryReader: (_) => fake,
              eligibilityReader: (_, _) => AvailabilitySuccess(eligible()),
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        fake.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DriverAvailabilityCard()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('جارٍ تحميل حالة التوفر'), findsOneWidget);
      expect(find.text('Loading availability'), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('Arabic default-deny profile missing', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootArabic(
        tester,
        fake,
        eligibilityReader: (_, _) =>
            const AvailabilityFailureResult(DriverProfileMissing()),
      );
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        find.text('تعذر التحقق من جاهزية حساب السائق حاليًا.'),
        findsOneWidget,
      );
      expect(find.text('غير متاح لاستقبال الطلبات'), findsOneWidget);
      expect(
        find.text('Driver account readiness could not be verified yet.'),
        findsNothing,
      );
      expect(fake.requestCallCount, 0);
    });

    testWidgets('Arabic locale drives RTL direction', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootArabic(tester, fake);
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality).first,
        ),
      );
      expect(directionality.textDirection, TextDirection.rtl);
      expect(find.byType(DriverAvailabilityCard), findsOneWidget);
    });

    testWidgets('long Arabic labels have no overflow', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootArabic(tester, fake, surfaceSize: const Size(320, 640));
      expect(tester.takeException(), isNull);
      expect(find.text('بدء استقبال الطلبات'), findsOneWidget);
    });

    testWidgets('Arabic large text scale has no overflow', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootArabic(
        tester,
        fake,
        textScale: 1.6,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('غير متاح لاستقبال الطلبات'), findsOneWidget);
    });
  });
}

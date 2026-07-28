import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/support/domain/entities/support_config.dart';
import 'package:saeq_driver/features/support/domain/repositories/support_repository.dart';
import 'package:saeq_driver/features/support/presentation/providers/support_providers.dart';
import 'package:saeq_driver/features/support/presentation/screens/support_safety_screen.dart';
import 'package:saeq_driver/features/support/presentation/screens/support_screen.dart';

class _UnavailableSupportRepository implements SupportRepository {
  @override
  Future<SupportConfig> getSupportConfig() async => SupportConfig.unavailable;
}

Future<void> _pumpSupportScreen(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.pumpWidget(child);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('SupportScreen shows unavailable contact state', (tester) async {
    await _pumpSupportScreen(
      tester,
      child: ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(
            _UnavailableSupportRepository(),
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
          home: const SupportScreen(),
        ),
      ),
    );

    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Frequently asked questions'), findsOneWidget);
    expect(find.text('Support unavailable'), findsWidgets);
  });

  testWidgets('SupportScreen expands FAQ answer on tap', (tester) async {
    await _pumpSupportScreen(
      tester,
      child: ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(
            _UnavailableSupportRepository(),
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
          home: const SupportScreen(),
        ),
      ),
    );

    const question = 'How do I receive delivery offers?';
    const answer =
        'Turn on availability from Home and stay signed in while online.';

    expect(find.text(question), findsOneWidget);
    expect(find.text(answer), findsNothing);

    await tester.tap(find.text(question));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(answer), findsOneWidget);
  });

  testWidgets('SupportScreen safety action navigates to safety tips', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SupportScreen()),
        GoRoute(
          path: AppRoutes.supportSafety,
          builder: (context, state) => const SupportSafetyScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpSupportScreen(
      tester,
      child: ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(
            _UnavailableSupportRepository(),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('en', 'US'),
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

    expect(find.text('Support unavailable'), findsWidgets);
    expect(find.text('How do I receive delivery offers?'), findsOneWidget);

    final safetyButton = find.byType(OutlinedButton);
    await tester.ensureVisible(safetyButton);
    expect(safetyButton, findsOneWidget);

    await tester.tap(safetyButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SupportSafetyScreen), findsOneWidget);
    expect(
      find.text('Follow traffic rules and wear required safety gear.'),
      findsOneWidget,
    );
  });
}

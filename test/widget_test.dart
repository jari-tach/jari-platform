import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/presentation/screens/splash_screen.dart';
import 'package:saeq_driver/features/driver/presentation/welcome_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

import 'test_bootstrap.dart';

void main() {
  testWidgets('Splash screen renders on cold start', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('App bootstrap smoke test', (WidgetTester tester) async {
    await pumpTestApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'SAEQ Driver');
  });

  testWidgets('Welcome screen has required elements after Splash tap', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(tester);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Tap splash to continue (also covered by timer in Batch 2 flow tests).
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byKey(const Key('welcomeStart')), findsOneWidget);
    expect(find.byType(SaeqPrimaryButton), findsWidgets);
    expect(find.byType(Text), findsWidgets);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';
import 'test_bootstrap.dart';

void main() {
  testWidgets('Welcome screen renders', (WidgetTester tester) async {
    // Use test bootstrap to properly initialize the app
    await pumpTestApp(tester);

    // Verify the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify Scaffold is present (welcome screen is displayed)
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('App bootstrap smoke test', (WidgetTester tester) async {
    // Use test bootstrap to properly initialize the app
    await pumpTestApp(tester);

    // Verify MaterialApp is built
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify the app has a title
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'SAEQ Driver');
  });

  testWidgets('Welcome screen has required elements', (WidgetTester tester) async {
    // Use test bootstrap to properly initialize the app
    await pumpTestApp(tester);

    // Verify the welcome screen is displayed
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Verify the explore button exists
    expect(find.byType(SaeqPrimaryButton), findsOneWidget);
    
    // Verify there is content on the screen
    expect(find.byType(Text), findsWidgets);
  });
}

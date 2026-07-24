import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saeq_driver/main.dart';

/// Test helper to create a testable app widget without full service initialization
Widget createTestableApp({Widget? child}) {
  return ProviderScope(
    child: MaterialApp(
      home: child ?? const SaeqApp(),
    ),
  );
}

/// Test helper to pump the app with ProviderScope
Future<void> pumpTestApp(WidgetTester tester, {Widget? child}) async {
  await tester.pumpWidget(createTestableApp(child: child));
  await tester.pumpAndSettle();
}
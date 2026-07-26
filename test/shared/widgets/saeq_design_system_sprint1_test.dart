import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/core/theme/saeq_semantic_colors.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_secondary_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_status_chip.dart';

void main() {
  Widget wrap(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: Scaffold(body: child),
    );
  }

  testWidgets('primary button loading disables press', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SaeqPrimaryButton(
          label: 'Go',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(tapped, isFalse);
  });

  testWidgets('primary button disabled when onPressed null', (tester) async {
    await tester.pumpWidget(wrap(const SaeqPrimaryButton(label: 'Go')));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('status chip includes icon and semantics', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SaeqStatusChip(label: 'Available', tone: SaeqStatusTone.success),
      ),
    );
    expect(find.text('Available'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
  });

  testWidgets('busy tone uses busy icon', (tester) async {
    await tester.pumpWidget(
      wrap(const SaeqStatusChip(label: 'Busy', tone: SaeqStatusTone.busy)),
    );
    expect(find.byIcon(Icons.hourglass_top_outlined), findsOneWidget);
  });

  testWidgets('dark theme resolves semantic colors', (tester) async {
    late SaeqSemanticColors colors;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            colors = SaeqSemanticColors.of(context);
            return const SizedBox.shrink();
          },
        ),
        mode: ThemeMode.dark,
      ),
    );
    expect(colors.primary, SaeqSemanticColors.dark.primary);
    expect(colors.surface, SaeqSemanticColors.dark.surface);
  });

  testWidgets('RTL secondary button still renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SaeqSecondaryButton(label: 'رفض', icon: Icons.close),
          ),
        ),
      ),
    );
    expect(find.text('رفض'), findsOneWidget);
  });

  testWidgets('text scale does not throw on primary button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SaeqPrimaryButton(label: 'تأكيد التسليم', onPressed: () {}),
          ),
        ),
      ),
    );
    expect(find.text('تأكيد التسليم'), findsOneWidget);
  });
}

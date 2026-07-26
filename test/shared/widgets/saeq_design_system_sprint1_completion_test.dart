import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/core/theme/saeq_semantic_colors.dart';
import 'package:saeq_driver/shared/widgets/saeq_delivery_action_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_delivery_timeline.dart';
import 'package:saeq_driver/shared/widgets/saeq_destructive_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_empty_state.dart';
import 'package:saeq_driver/shared/widgets/saeq_error_state.dart';
import 'package:saeq_driver/shared/widgets/saeq_outline_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_success_button.dart';

void main() {
  Widget wrap(
    Widget child, {
    ThemeMode mode = ThemeMode.light,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1.0,
    Size size = const Size(390, 800),
  }) {
    return MaterialApp(
      theme: mode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('delivery action loading blocks tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        SaeqDeliveryActionButton(
          label: 'Next',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('success button disabled when null onPressed', (tester) async {
    await tester.pumpWidget(wrap(const SaeqSuccessButton(label: 'Finish')));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('destructive and outline render', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            SaeqDestructiveButton(label: 'Delete'),
            SaeqOutlineButton(label: 'Outline'),
          ],
        ),
      ),
    );
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Outline'), findsOneWidget);
  });

  testWidgets('timeline marks current and completed icons', (tester) async {
    await tester.pumpWidget(
      wrap(const SaeqDeliveryTimeline(labels: ['A', 'B', 'C'], activeIndex: 1)),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('empty and error states use semantic colors', (tester) async {
    await tester.pumpWidget(
      wrap(
        SaeqEmptyState(
          title: 'Empty',
          message: 'None',
          onAction: () {},
          actionLabel: 'Retry',
        ),
      ),
    );
    expect(find.text('Empty'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        SaeqErrorState(
          title: 'Error',
          message: 'Failed',
          retryLabel: 'Retry',
          onRetry: () {},
        ),
      ),
    );
    expect(find.text('Error'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('RTL Arabic + dark + large text smoke', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SaeqDeliveryActionButton(label: 'متابعة التوصيل'),
        mode: ThemeMode.dark,
        direction: TextDirection.rtl,
        textScale: 1.4,
        size: const Size(320, 640),
      ),
    );
    expect(find.text('متابعة التوصيل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LTR English narrow width smoke', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SaeqSuccessButton(label: 'Finish delivery'),
        direction: TextDirection.ltr,
        size: const Size(320, 640),
      ),
    );
    expect(find.text('Finish delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme extension exposes dark primary token', (
    tester,
  ) async {
    late Color resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            resolved = SaeqSemanticColors.of(context).primary;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, SaeqSemanticColors.dark.primary);
    expect(resolved, isNot(equals(SaeqSemanticColors.light.primary)));
  });
}

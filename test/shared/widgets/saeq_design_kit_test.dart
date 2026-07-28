import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/shared/widgets/saeq_confirm_dialog.dart';
import 'package:saeq_driver/shared/widgets/saeq_destructive_dialog.dart';
import 'package:saeq_driver/shared/widgets/saeq_empty_state.dart';
import 'package:saeq_driver/shared/widgets/saeq_error_state.dart';
import 'package:saeq_driver/shared/widgets/saeq_offline_banner.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_secondary_button.dart';
import 'package:saeq_driver/shared/widgets/saeq_status_chip.dart';

void main() {
  testWidgets('SaeqEmptyState shows action when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaeqEmptyState(
            title: 'Empty',
            message: 'Nothing here',
            actionLabel: 'Retry',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.byKey(SaeqEmptyState.emptyKey), findsOneWidget);
    await tester.tap(find.byKey(SaeqEmptyState.actionKey));
    expect(tapped, isTrue);
  });

  testWidgets('SaeqErrorState retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaeqErrorState(
            title: 'Error',
            message: 'Failed',
            retryLabel: 'Retry',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    expect(retried, isTrue);
  });

  testWidgets('SaeqPrimaryButton respects isLoading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaeqPrimaryButton(
            label: 'Go',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('SaeqSecondaryButton renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SaeqSecondaryButton(label: 'Secondary')),
      ),
    );
    expect(find.text('Secondary'), findsOneWidget);
  });

  testWidgets('SaeqStatusChip and offline banner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SaeqStatusChip(label: 'Available', tone: SaeqStatusTone.success),
              SaeqOfflineBanner(message: 'Offline now'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Available'), findsOneWidget);
    expect(find.byKey(SaeqOfflineBanner.bannerKey), findsOneWidget);
  });

  testWidgets('SaeqConfirmDialog returns true on confirm', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await SaeqConfirmDialog.show(
                    context,
                    title: 'Confirm?',
                    message: 'Sure?',
                    confirmLabel: 'Yes',
                    cancelLabel: 'No',
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saeqConfirmDialogConfirm')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('SaeqDestructiveDialog cancel returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await SaeqDestructiveDialog.show(
                    context,
                    title: 'Sign out?',
                    message: 'Really?',
                    confirmLabel: 'Sign Out',
                    cancelLabel: 'Cancel',
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saeqDestructiveDialogCancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/core/theme/saeq_semantic_colors.dart';
import 'package:saeq_driver/shared/widgets/saeq_earnings_row.dart';
import 'package:saeq_driver/shared/widgets/saeq_filter_chip_bar.dart';
import 'package:saeq_driver/shared/widgets/saeq_notification_row.dart';

Future<void> pumpWrapped(
  WidgetTester tester,
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  TextDirection direction = TextDirection.ltr,
  Locale locale = const Locale('en', 'US'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: mode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('SaeqFilterChipBar', () {
    testWidgets('history filter chips render with labels', (tester) async {
      await pumpWrapped(
        tester,
        SaeqFilterChipBar(
          chips: [
            SaeqFilterChip(label: 'All', selected: true, onTap: () {}),
            SaeqFilterChip(label: 'Delivered', selected: false, onTap: () {}),
            SaeqFilterChip(label: 'Cancelled', selected: false, onTap: () {}),
          ],
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('selected chip uses semantic primary container', (
      tester,
    ) async {
      late Color selectedBackground;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              selectedBackground = SaeqSemanticColors.of(
                context,
              ).primaryContainer;
              return Scaffold(
                body: SaeqFilterChipBar(
                  chips: [
                    SaeqFilterChip(
                      label: 'Today',
                      selected: true,
                      onTap: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      final chipFinder = find.byType(SaeqFilterChip);
      expect(chipFinder, findsOneWidget);
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: chipFinder,
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration! as BoxDecoration;
      expect(decoration.color, selectedBackground);
    });
  });

  group('SaeqNotificationRow', () {
    testWidgets('unread chip finds text and icon', (tester) async {
      await pumpWrapped(
        tester,
        const SaeqNotificationRow(
          title: 'New delivery offer',
          body: 'A new offer is available.',
          isRead: false,
          readLabel: 'Read',
          unreadLabel: 'Unread',
        ),
      );

      expect(find.text('Unread'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      expect(find.text('New delivery offer'), findsOneWidget);
    });

    testWidgets('read chip shows read label', (tester) async {
      await pumpWrapped(
        tester,
        const SaeqNotificationRow(
          title: 'System notice',
          body: 'Keep the app updated.',
          isRead: true,
          readLabel: 'Read',
          unreadLabel: 'Unread',
        ),
      );

      expect(find.text('Read'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
    });
  });

  group('SaeqEarningsRow', () {
    testWidgets('renders amount with monetary style', (tester) async {
      await pumpWrapped(
        tester,
        const SaeqEarningsRow(
          title: 'Today',
          subtitle: '3 trips',
          amountLabel: 'SAR 42.5',
        ),
      );

      expect(find.text('SAR 42.5'), findsOneWidget);
      final amountText = tester.widget<Text>(find.text('SAR 42.5'));
      expect(amountText.style?.fontWeight, FontWeight.w700);
    });
  });

  group('RTL smoke', () {
    testWidgets('filter chips RTL Arabic', (tester) async {
      await pumpWrapped(
        tester,
        SaeqFilterChipBar(
          chips: [
            SaeqFilterChip(label: 'الكل', selected: true, onTap: () {}),
            SaeqFilterChip(label: 'مُسلَّم', selected: false, onTap: () {}),
          ],
        ),
        direction: TextDirection.rtl,
        locale: const Locale('ar', 'SA'),
      );

      expect(find.text('الكل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notification row RTL Arabic', (tester) async {
      await pumpWrapped(
        tester,
        const SaeqNotificationRow(
          title: 'عرض توصيل جديد',
          body: 'يتوفر عرض جديد أثناء اتصالك.',
          isRead: false,
          readLabel: 'مقروء',
          unreadLabel: 'غير مقروء',
        ),
        direction: TextDirection.rtl,
        locale: const Locale('ar', 'SA'),
      );

      expect(find.text('غير مقروء'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('dark theme smoke', () {
    testWidgets('earnings row dark theme', (tester) async {
      late Color primary;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              primary = SaeqSemanticColors.of(context).primary;
              return const Scaffold(
                body: SaeqEarningsRow(
                  title: 'This week',
                  subtitle: '5 trips',
                  amountLabel: 'SAR 120.0',
                ),
              );
            },
          ),
        ),
      );

      final amountText = tester.widget<Text>(find.text('SAR 120.0'));
      expect(amountText.style?.color, primary);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notification row dark theme', (tester) async {
      await pumpWrapped(
        tester,
        const SaeqNotificationRow(
          title: 'Payout update',
          body: 'Your trial earnings summary was updated.',
          isRead: false,
          readLabel: 'Read',
          unreadLabel: 'Unread',
        ),
        mode: ThemeMode.dark,
      );

      expect(find.text('Unread'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('earnings filter chips dark theme', (tester) async {
      await pumpWrapped(
        tester,
        SaeqFilterChipBar(
          chips: [
            SaeqFilterChip(label: 'All', selected: true, onTap: () {}),
            SaeqFilterChip(label: 'Today', selected: false, onTap: () {}),
          ],
        ),
        mode: ThemeMode.dark,
      );

      expect(find.byType(SaeqFilterChip), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}

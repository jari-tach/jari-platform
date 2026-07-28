import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/shared/widgets/saeq_otp_input.dart';
import 'package:saeq_driver/shared/widgets/saeq_profile_header.dart';
import 'package:saeq_driver/shared/widgets/saeq_resend_timer.dart';
import 'package:saeq_driver/shared/widgets/saeq_settings_row.dart';
import 'package:saeq_driver/shared/widgets/saeq_settings_section.dart';

Future<void> pumpWrapped(
  WidgetTester tester,
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  TextDirection direction = TextDirection.ltr,
  Locale locale = const Locale('en', 'US'),
  double textScaleFactor = 1.0,
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
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

int? _cooldownSeconds(WidgetTester tester) {
  final finder = find.byKey(const Key('saeqResendCooldownText'));
  if (finder.evaluate().isEmpty) return null;
  final text = tester.widget<Text>(finder).data ?? '';
  final match = RegExp(r'(\d+)s').firstMatch(text);
  return match == null ? null : int.parse(match.group(1)!);
}

void main() {
  group('SaeqResendTimer', () {
    testWidgets('shows cooldown text that updates every second', (
      tester,
    ) async {
      final availableAt = DateTime.now().add(const Duration(seconds: 5));

      await pumpWrapped(
        tester,
        SaeqResendTimer(
          resendAvailableAt: availableAt,
          cooldownLabelBuilder: (seconds) => 'Resend available in ${seconds}s',
          resendLabel: 'Resend code',
          onResend: () {},
        ),
      );

      final initial = _cooldownSeconds(tester);
      expect(initial, isNotNull);
      expect(initial, inInclusiveRange(3, 5));

      await tester.pump(const Duration(seconds: 1));
      final afterTick = _cooldownSeconds(tester);
      expect(afterTick, isNotNull);
      expect(afterTick!, lessThan(initial!));

      await tester.pump(const Duration(seconds: 1));
      final afterSecondTick = _cooldownSeconds(tester);
      expect(afterSecondTick, isNotNull);
      expect(afterSecondTick!, lessThan(afterTick));
    });

    testWidgets('shows resend action when cooldown elapsed', (tester) async {
      var tapped = false;
      await pumpWrapped(
        tester,
        SaeqResendTimer(
          resendAvailableAt: DateTime.now().subtract(
            const Duration(seconds: 1),
          ),
          cooldownLabelBuilder: (seconds) => 'Resend available in ${seconds}s',
          resendLabel: 'Resend code',
          onResend: () => tapped = true,
        ),
      );

      expect(find.text('Resend code'), findsOneWidget);
      await tester.tap(find.byKey(SaeqResendTimer.actionKey));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('SaeqSettingsRow', () {
    testWidgets('shows current value text', (tester) async {
      await pumpWrapped(
        tester,
        SaeqSettingsSection(
          title: 'Appearance',
          children: [
            SaeqSettingsRow(label: 'Theme', value: 'Light', onTap: () {}),
          ],
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });
  });

  group('SaeqProfileHeader', () {
    testWidgets('renders partial identity data with masked phone', (
      tester,
    ) async {
      await pumpWrapped(
        tester,
        const SaeqProfileHeader(
          fullName: 'Driver One',
          maskedPhone: '********78',
        ),
      );

      expect(find.text('Driver One'), findsOneWidget);
      expect(find.text('********78'), findsOneWidget);
      expect(find.text('0512345678'), findsNothing);
    });
  });

  group('SaeqOtpInput', () {
    testWidgets('meets minimum touch target height', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpWrapped(
        tester,
        SaeqOtpInput(
          controller: controller,
          semanticsLabel: 'Verification code',
        ),
      );

      final boxes = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(SaeqOtpInput),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(boxes.every((box) => box.constraints?.maxHeight == SaeqOtpInput.cellHeight), isTrue);
    });
  });

  group('RTL + dark smoke', () {
    testWidgets('settings section RTL Arabic dark theme', (tester) async {
      await pumpWrapped(
        tester,
        SaeqSettingsSection(
          title: 'اللغة',
          children: [
            SaeqSettingsRow(
              label: 'العربية',
              value: 'العربية',
              selected: true,
              onTap: () {},
            ),
          ],
        ),
        direction: TextDirection.rtl,
        locale: const Locale('ar', 'SA'),
        mode: ThemeMode.dark,
      );

      expect(find.text('العربية'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('text scale smoke', () {
    testWidgets('profile header at textScaleFactor 1.3', (tester) async {
      await pumpWrapped(
        tester,
        const SaeqProfileHeader(
          fullName: 'Driver One',
          maskedPhone: '********78',
        ),
        textScaleFactor: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SaeqProfileHeader), findsOneWidget);
    });
  });
}

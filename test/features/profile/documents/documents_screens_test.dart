import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/profile/documents/document_upload_screen.dart';
import 'package:saeq_driver/features/profile/documents/documents_feature.dart';
import 'package:saeq_driver/features/profile/documents/documents_list_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

Future<void> _pumpDocumentsList(
  WidgetTester tester, {
  required DocumentsRepository repository,
  Locale locale = const Locale('en', 'US'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
  Size surface = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDocumentsUpload,
        builder: (context, state) => const DocumentUploadScreen(),
      ),
      GoRoute(
        path: '/profile/documents/:id',
        builder: (context, state) =>
            DocumentDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [documentsRepositoryProvider.overrideWithValue(repository)],
      child: MediaQuery(
        data: MediaQueryData(
          size: surface,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(
          locale: locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
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
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('Documents list shows all review statuses', (tester) async {
    await _pumpDocumentsList(tester, repository: FakeDocumentsRepository());

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Expiring soon'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Expired'), 200);
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('Documents list shows eligibility banner and date subtitles', (
    tester,
  ) async {
    await _pumpDocumentsList(tester, repository: FakeDocumentsRepository());

    expect(
      find.byKey(DocumentsListScreen.eligibilityBannerKey),
      findsOneWidget,
    );
    expect(find.text('Eligibility summary'), findsOneWidget);
    expect(find.textContaining('Expires'), findsWidgets);
    expect(find.textContaining('Uploaded'), findsOneWidget);
  });

  testWidgets('Documents list loading state', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(
        latency: const Duration(milliseconds: 800),
      ),
    );
    expect(find.text('Loading documents'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('Document approved detail', (tester) async {
    await _pumpDocumentsList(tester, repository: FakeDocumentsRepository());
    await tester.tap(find.byKey(const Key('documentRow-doc-approved')));
    await tester.pumpAndSettle();
    expect(find.text('National ID'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('•••• •••• 4821'), findsOneWidget);
  });

  testWidgets('Document under review detail', (tester) async {
    await _pumpDocumentsList(tester, repository: FakeDocumentsRepository());
    await tester.tap(find.byKey(const Key('documentRow-doc-review')));
    await tester.pumpAndSettle();
    expect(find.text('Under review'), findsOneWidget);
    expect(
      find.textContaining('Going available may be blocked'),
      findsOneWidget,
    );
  });

  testWidgets('Document rejected detail localizes reason in Arabic', (
    tester,
  ) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(),
      locale: const Locale('ar'),
    );

    await tester.tap(find.byKey(const Key('documentRow-doc-rejected')));
    await tester.pumpAndSettle();

    expect(find.text('•••• •••• 7712'), findsOneWidget);
    expect(find.text('عدم تطابق رقم اللوحة'), findsOneWidget);
    expect(find.text('Plate number mismatch'), findsNothing);
    expect(find.textContaining('اعتماد المركبة'), findsOneWidget);
  });

  testWidgets('Document expired detail', (tester) async {
    await _pumpDocumentsList(tester, repository: FakeDocumentsRepository());
    final expiredRow = find.byKey(const Key('documentRow-doc-expired'));
    await tester.scrollUntilVisible(expiredRow, 300);
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(expiredRow);
    await tester.pumpAndSettle();
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('•••• •••• 2208'), findsOneWidget);
  });

  testWidgets('Documents empty state', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(mode: FakeDocumentsMode.empty),
    );
    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('Documents error state', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(mode: FakeDocumentsMode.error),
    );
    expect(find.text('Could not load documents'), findsOneWidget);
  });

  testWidgets('Documents offline state', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(mode: FakeDocumentsMode.offline),
    );
    expect(find.text('Documents unavailable offline'), findsOneWidget);
  });

  testWidgets('Document upload fake file success flow', (tester) async {
    await _pumpDocumentsList(tester, repository: FakeDocumentsRepository());

    await tester.tap(find.byKey(DocumentsListScreen.uploadKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DocumentUploadScreen.uploadKey));
    await tester.pump();
    expect(find.text('Select a trial file before submitting.'), findsOneWidget);

    await tester.tap(find.byKey(DocumentUploadScreen.selectFileKey));
    await tester.pump();
    expect(find.text('trial-document.pdf'), findsOneWidget);

    await tester.tap(find.byKey(DocumentUploadScreen.uploadKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Document uploaded.'), findsWidgets);
  });

  testWidgets('Document uploading disables submit', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(
        latency: const Duration(milliseconds: 800),
      ),
    );
    await tester.tap(find.byKey(DocumentsListScreen.uploadKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DocumentUploadScreen.selectFileKey));
    await tester.pump();
    await tester.tap(find.byKey(DocumentUploadScreen.uploadKey));
    await tester.pump();

    final button = tester.widget<SaeqPrimaryButton>(
      find.byKey(DocumentUploadScreen.uploadKey),
    );
    expect(button.onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('Document upload failure shows retryable error', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(failUpload: true),
    );
    await tester.tap(find.byKey(DocumentsListScreen.uploadKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DocumentUploadScreen.selectFileKey));
    await tester.pump();
    await tester.tap(find.byKey(DocumentUploadScreen.uploadKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Upload failed. Please try again.'), findsOneWidget);
  });

  testWidgets('Documents Arabic narrow text scale smoke', (tester) async {
    await _pumpDocumentsList(
      tester,
      repository: FakeDocumentsRepository(),
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 1.3,
      surface: const Size(320, 800),
    );
    expect(find.text('المستندات'), findsOneWidget);
    expect(find.text('ملخص الأهلية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

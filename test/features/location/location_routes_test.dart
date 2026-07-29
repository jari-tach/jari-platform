import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/location/location_screen.dart';
import 'package:saeq_driver/features/location/map_preview_screen.dart';
import 'package:saeq_driver/features/profile/presentation/screens/profile_screen.dart';

import '../../integration/fake_e2e_harness.dart';

void main() {
  test('STEP 2B routes are protected', () {
    expect(AppRoutes.isProtected(AppRoutes.location), isTrue);
    expect(AppRoutes.isProtected(AppRoutes.mapPreview), isTrue);
  });

  testWidgets('App router resolves /location and /map/preview', (tester) async {
    final harness = await createFakeE2eContainer();
    addTearDown(() {
      harness.container.dispose();
      harness.authRepository.dispose();
      harness.availabilityRepository.dispose();
      tester.binding.setSurfaceSize(null);
    });

    final router = await pumpFakeE2eApp(tester, harness.container);

    router.go(AppRoutes.location);
    await pumpFakeE2eBounded(tester);
    expect(router.state.uri.path, AppRoutes.location);
    expect(find.byType(LocationScreen), findsOneWidget);

    router.go(AppRoutes.mapPreview);
    await pumpFakeE2eBounded(tester);
    expect(router.state.uri.path, AppRoutes.mapPreview);
    expect(find.byType(MapPreviewScreen), findsOneWidget);
  });

  testWidgets('Profile location row opens the location route', (tester) async {
    final harness = await createFakeE2eContainer();
    addTearDown(() {
      harness.container.dispose();
      harness.authRepository.dispose();
      harness.availabilityRepository.dispose();
      tester.binding.setSurfaceSize(null);
    });

    final router = await pumpFakeE2eApp(tester, harness.container);

    router.go(AppRoutes.profile);
    await pumpFakeE2eBounded(tester);

    final rowFinder = find.byKey(ProfileScreen.locationRowKey);
    await tester.ensureVisible(rowFinder);
    await pumpFakeE2eBounded(tester);
    await tester.tap(rowFinder);
    await pumpFakeE2eBounded(tester);

    expect(router.state.uri.path, AppRoutes.location);
    expect(find.byType(LocationScreen), findsOneWidget);
  });
}

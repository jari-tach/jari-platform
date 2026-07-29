import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/batch/batch_feature.dart';
import 'package:saeq_driver/features/batch/batch_view_data.dart';
import 'package:saeq_driver/features/batch/batch_issue_screen.dart';
import 'package:saeq_driver/features/batch/batch_offer_screen.dart';
import 'package:saeq_driver/features/batch/batch_pickup_screen.dart';
import 'package:saeq_driver/features/batch/batch_route_screen.dart';
import 'package:saeq_driver/features/batch/batch_stop_screen.dart';
import 'package:saeq_driver/features/batch/batch_summary_screen.dart';
import 'package:saeq_driver/features/batch/batch_verify_screen.dart';

import '../../integration/fake_e2e_harness.dart';

void main() {
  const batchId = FakeBatchService.defaultBatchId;

  test('STEP 2C batch routes are protected', () {
    expect(AppRoutes.isProtected(AppRoutes.batchOfferPath(batchId)), isTrue);
    expect(AppRoutes.isProtected(AppRoutes.batchPickupPath(batchId)), isTrue);
    expect(AppRoutes.isProtected(AppRoutes.batchVerifyPath(batchId)), isTrue);
    expect(AppRoutes.isProtected(AppRoutes.batchRoutePath(batchId)), isTrue);
    expect(AppRoutes.isProtected(AppRoutes.batchStopPath(batchId, 1)), isTrue);
    expect(
      AppRoutes.isProtected(AppRoutes.batchIssuePath(batchId, 'B-2031')),
      isTrue,
    );
    expect(AppRoutes.isProtected(AppRoutes.batchSummaryPath(batchId)), isTrue);
  });

  testWidgets('App router resolves all seven batch routes', (tester) async {
    final batch = FakeBatchService.batchFixture(orderCount: 4);
    final harness = await createFakeE2eContainer(
      extraOverrides: [
        batchServiceProvider.overrideWithValue(
          FakeBatchService(latency: Duration.zero),
        ),
        batchControllerProvider.overrideWith(
          () => _SeededBatchController(batch),
        ),
      ],
    );
    addTearDown(() {
      harness.container.dispose();
      harness.authRepository.dispose();
      harness.availabilityRepository.dispose();
      tester.binding.setSurfaceSize(null);
    });

    final router = await pumpFakeE2eApp(tester, harness.container);

    router.go(AppRoutes.batchOfferPath(batchId));
    await pumpFakeE2eBounded(tester);
    expect(find.byType(BatchOfferScreen), findsOneWidget);

    router.go(AppRoutes.batchPickupPath(batchId));
    await pumpFakeE2eBounded(tester);
    expect(find.byType(BatchPickupScreen), findsOneWidget);

    router.go(AppRoutes.batchVerifyPath(batchId));
    await pumpFakeE2eBounded(tester);
    expect(find.byType(BatchVerifyScreen), findsOneWidget);

    router.go(AppRoutes.batchRoutePath(batchId));
    await pumpFakeE2eBounded(tester);
    expect(find.byType(BatchRouteScreen), findsOneWidget);

    router.go(AppRoutes.batchStopPath(batchId, 1));
    await pumpFakeE2eBounded(tester);
    expect(find.byType(BatchStopScreen), findsOneWidget);

    router.go(AppRoutes.batchIssuePath(batchId, 'B-2031'));
    await pumpFakeE2eBounded(tester);
    await tester.pumpAndSettle();
    expect(find.byType(BatchIssueScreen), findsOneWidget);

    router.go(AppRoutes.batchSummaryPath(batchId));
    await pumpFakeE2eBounded(tester);
    expect(find.byType(BatchSummaryScreen), findsOneWidget);
  });
}

class _SeededBatchController extends BatchController {
  _SeededBatchController(this.batch);

  final BatchOfferViewData batch;

  @override
  BatchState build() => BatchState(
    batch: batch,
    offerStatus: BatchOfferViewStatus.accepted,
    pickupStatus: BatchPickupStatus.pickupConfirmed,
    routeStatus: BatchRouteStatus.overview,
    tripStarted: true,
    currentSequence: 1,
  );
}

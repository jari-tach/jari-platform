import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/earnings/data/fake/fake_earnings_repository.dart';
import 'package:saeq_driver/features/earnings/domain/entities/earnings_period.dart';
import 'package:saeq_driver/features/history/data/fake/fake_delivery_history_repository.dart';
import 'package:saeq_driver/features/history/domain/entities/delivery_history_item.dart';
import 'package:saeq_driver/features/notifications/data/fake/fake_notifications_repository.dart';

void main() {
  group('FakeDeliveryHistoryRepository', () {
    test('filters delivered and cancelled', () async {
      final repo = FakeDeliveryHistoryRepository(
        isProductionEnvironment: () => false,
      );
      final all = await repo.listHistory();
      expect(all.length, greaterThanOrEqualTo(3));
      final delivered = await repo.listHistory(
        filter: DeliveryHistoryFilter.delivered,
      );
      expect(delivered.every((e) => e.statusLabelKey == 'delivered'), isTrue);
      final cancelled = await repo.listHistory(
        filter: DeliveryHistoryFilter.cancelled,
      );
      expect(cancelled.every((e) => e.statusLabelKey == 'cancelled'), isTrue);
    });

    test('getById returns seeded item', () async {
      final repo = FakeDeliveryHistoryRepository(
        isProductionEnvironment: () => false,
      );
      final item = await repo.getById('hist-001');
      expect(item, isNotNull);
      expect(item!.storeName, contains('Merchant'));
    });

    test('production construction throws', () {
      expect(
        () =>
            FakeDeliveryHistoryRepository(isProductionEnvironment: () => true),
        throwsStateError,
      );
    });
  });

  group('FakeEarningsRepository', () {
    test('today filter returns one period', () async {
      final repo = FakeEarningsRepository(isProductionEnvironment: () => false);
      final today = await repo.listPeriods(filter: EarningsFilter.today);
      expect(today, hasLength(1));
      expect(today.first.labelKey, 'today');
    });

    test('production construction throws', () {
      expect(
        () => FakeEarningsRepository(isProductionEnvironment: () => true),
        throwsStateError,
      );
    });
  });

  group('FakeNotificationsRepository', () {
    test('markRead clears unread', () async {
      final repo = FakeNotificationsRepository(
        isProductionEnvironment: () => false,
      );
      final beforeCount = await repo.unreadCount();
      expect(beforeCount, greaterThan(0));
      final after = await repo.markRead('notif-001');
      expect(after!.isRead, isTrue);
      expect(await repo.unreadCount(), beforeCount - 1);
    });

    test('production construction throws', () {
      expect(
        () => FakeNotificationsRepository(isProductionEnvironment: () => true),
        throwsStateError,
      );
    });
  });
}

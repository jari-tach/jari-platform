import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/history/data/fake/fake_delivery_history_repository.dart';
import 'package:saeq_driver/features/history/domain/entities/delivery_history_item.dart';
import 'package:saeq_driver/features/history/domain/repositories/delivery_history_repository.dart';
import 'package:saeq_driver/features/history/presentation/providers/history_providers.dart';

class _FailingHistoryRepo implements DeliveryHistoryRepository {
  @override
  Future<DeliveryHistoryItem?> getById(String id) async => null;

  @override
  Future<List<DeliveryHistoryItem>> listHistory({
    DeliveryHistoryFilter filter = DeliveryHistoryFilter.all,
  }) async {
    throw StateError('history_load_forced_failure');
  }
}

void main() {
  group('HistoryController', () {
    test('loads fake seed without claiming live workflow linkage', () async {
      final repo = FakeDeliveryHistoryRepository(
        isProductionEnvironment: () => false,
      );
      final container = ProviderContainer(
        overrides: [deliveryHistoryRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(historyControllerProvider.notifier).load();
      final state = container.read(historyControllerProvider);
      expect(state.loading, isFalse);
      expect(state.failureMessage, isNull);
      expect(state.items, isNotEmpty);
      // Fake Alpha seed ids — not assignment IDs from delivery workflow.
      expect(state.items.first.id, startsWith('hist-'));
    });

    test('failure state through controller', () async {
      final container = ProviderContainer(
        overrides: [
          deliveryHistoryRepositoryProvider.overrideWithValue(
            _FailingHistoryRepo(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(historyControllerProvider.notifier).load();
      final state = container.read(historyControllerProvider);
      expect(state.failureMessage, 'load_failed');
      expect(state.loading, isFalse);
    });

    test('filter switching', () async {
      final repo = FakeDeliveryHistoryRepository(
        isProductionEnvironment: () => false,
      );
      final container = ProviderContainer(
        overrides: [deliveryHistoryRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(historyControllerProvider.notifier);
      await controller.load();
      await controller.setFilter(DeliveryHistoryFilter.cancelled);
      final state = container.read(historyControllerProvider);
      expect(state.filter, DeliveryHistoryFilter.cancelled);
      expect(state.items.every((e) => e.statusLabelKey == 'cancelled'), isTrue);
    });
  });

  group('FakeDeliveryHistoryRepository guards', () {
    test('production construction throws', () {
      expect(
        () =>
            FakeDeliveryHistoryRepository(isProductionEnvironment: () => true),
        throwsStateError,
      );
    });
  });
}

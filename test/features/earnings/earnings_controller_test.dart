import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/earnings/data/fake/fake_earnings_repository.dart';
import 'package:saeq_driver/features/earnings/domain/entities/earnings_period.dart';
import 'package:saeq_driver/features/earnings/domain/repositories/earnings_repository.dart';
import 'package:saeq_driver/features/earnings/presentation/providers/earnings_providers.dart';

class _FailingEarningsRepo implements EarningsRepository {
  @override
  Future<EarningsPeriod?> getById(String id) async => null;

  @override
  Future<List<EarningsPeriod>> listPeriods({
    EarningsFilter filter = EarningsFilter.all,
  }) async {
    throw StateError('earnings_load_forced_failure');
  }
}

class _EmptyEarningsRepo implements EarningsRepository {
  @override
  Future<EarningsPeriod?> getById(String id) async => null;

  @override
  Future<List<EarningsPeriod>> listPeriods({
    EarningsFilter filter = EarningsFilter.all,
  }) async => const [];
}

void main() {
  group('EarningsController', () {
    test('successful fake load', () async {
      final repo = FakeEarningsRepository(isProductionEnvironment: () => false);
      final container = ProviderContainer(
        overrides: [earningsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(earningsControllerProvider.notifier).load();
      final state = container.read(earningsControllerProvider);
      expect(state.loading, isFalse);
      expect(state.failureMessage, isNull);
      expect(state.items, isNotEmpty);
      // Fake Alpha: amounts are seeded doubles only — no settlement claims.
      expect(state.items.first.amountSar, isA<double>());
    });

    test('loading then failure state', () async {
      final container = ProviderContainer(
        overrides: [
          earningsRepositoryProvider.overrideWithValue(_FailingEarningsRepo()),
        ],
      );
      addTearDown(container.dispose);

      final future = container.read(earningsControllerProvider.notifier).load();
      expect(container.read(earningsControllerProvider).loading, isTrue);
      await future;
      final state = container.read(earningsControllerProvider);
      expect(state.loading, isFalse);
      expect(state.failureMessage, 'load_failed');
    });

    test('empty state when repository returns no periods', () async {
      final container = ProviderContainer(
        overrides: [
          earningsRepositoryProvider.overrideWithValue(_EmptyEarningsRepo()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(earningsControllerProvider.notifier).load();
      final state = container.read(earningsControllerProvider);
      expect(state.items, isEmpty);
      expect(state.failureMessage, isNull);
    });

    test('filter switching uses fake seeded values', () async {
      final repo = FakeEarningsRepository(isProductionEnvironment: () => false);
      final container = ProviderContainer(
        overrides: [earningsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(earningsControllerProvider.notifier);
      await controller.load();
      await controller.setFilter(EarningsFilter.today);
      final today = container.read(earningsControllerProvider);
      expect(today.filter, EarningsFilter.today);
      expect(today.items, hasLength(1));
      expect(today.items.first.labelKey, 'today');
    });
  });

  group('FakeEarningsRepository guards', () {
    test('production construction throws', () {
      expect(
        () => FakeEarningsRepository(isProductionEnvironment: () => true),
        throwsStateError,
      );
    });
  });
}

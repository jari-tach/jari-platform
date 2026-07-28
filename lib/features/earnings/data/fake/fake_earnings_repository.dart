import '../../../../core/config/app_config.dart';
import '../../domain/entities/earnings_period.dart';
import '../../domain/repositories/earnings_repository.dart';

class FakeEarningsRepository implements EarningsRepository {
  FakeEarningsRepository({
    required bool Function() isProductionEnvironment,
    List<EarningsPeriod>? seed,
  }) : _items = List.unmodifiable(seed ?? _defaultSeed) {
    if (isProductionEnvironment()) {
      throw StateError(
        'FakeEarningsRepository must not be constructed in production.',
      );
    }
  }

  final List<EarningsPeriod> _items;

  static final _defaultSeed = <EarningsPeriod>[
    EarningsPeriod(
      id: 'earn-today',
      labelKey: 'today',
      amountSar: 185.5,
      tripsCount: 7,
      startsAt: DateTime.utc(2026, 7, 26),
      endsAt: DateTime.utc(2026, 7, 26, 23, 59),
    ),
    EarningsPeriod(
      id: 'earn-week',
      labelKey: 'week',
      amountSar: 940,
      tripsCount: 38,
      startsAt: DateTime.utc(2026, 7, 20),
      endsAt: DateTime.utc(2026, 7, 26, 23, 59),
    ),
    EarningsPeriod(
      id: 'earn-month',
      labelKey: 'month',
      amountSar: 3120.75,
      tripsCount: 126,
      startsAt: DateTime.utc(2026, 7, 1),
      endsAt: DateTime.utc(2026, 7, 26, 23, 59),
    ),
  ];

  factory FakeEarningsRepository.forApp() {
    return FakeEarningsRepository(
      isProductionEnvironment: () => AppConfig.isProduction,
    );
  }

  @override
  Future<List<EarningsPeriod>> listPeriods({
    EarningsFilter filter = EarningsFilter.all,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (filter == EarningsFilter.all) {
      return List.unmodifiable(_items);
    }
    final key = switch (filter) {
      EarningsFilter.today => 'today',
      EarningsFilter.week => 'week',
      EarningsFilter.month => 'month',
      EarningsFilter.all => 'all',
    };
    return List.unmodifiable(_items.where((e) => e.labelKey == key));
  }

  @override
  Future<EarningsPeriod?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

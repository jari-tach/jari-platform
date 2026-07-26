import '../../../../core/config/app_config.dart';
import '../../domain/entities/delivery_history_item.dart';
import '../../domain/repositories/delivery_history_repository.dart';

/// Deterministic Fake history (debug / non-production only).
class FakeDeliveryHistoryRepository implements DeliveryHistoryRepository {
  FakeDeliveryHistoryRepository({
    required bool Function() isProductionEnvironment,
    List<DeliveryHistoryItem>? seed,
  }) : _items = List.unmodifiable(seed ?? _defaultSeed) {
    if (isProductionEnvironment()) {
      throw StateError(
        'FakeDeliveryHistoryRepository must not be constructed in production.',
      );
    }
  }

  final List<DeliveryHistoryItem> _items;

  static final _defaultSeed = <DeliveryHistoryItem>[
    DeliveryHistoryItem(
      id: 'hist-001',
      storeName: 'Merchant Alpha',
      pickupLabel: 'Pickup Downtown',
      dropoffLabel: 'Dropoff North',
      completedAt: DateTime.utc(2026, 7, 26, 8, 30),
      earningsSar: 28.5,
      statusLabelKey: 'delivered',
    ),
    DeliveryHistoryItem(
      id: 'hist-002',
      storeName: 'Merchant Beta',
      pickupLabel: 'Pickup Mall',
      dropoffLabel: 'Dropoff East',
      completedAt: DateTime.utc(2026, 7, 25, 19, 10),
      earningsSar: 22,
      statusLabelKey: 'delivered',
    ),
    DeliveryHistoryItem(
      id: 'hist-003',
      storeName: 'Merchant Gamma',
      pickupLabel: 'Pickup West',
      dropoffLabel: 'Dropoff South',
      completedAt: DateTime.utc(2026, 7, 24, 14, 5),
      earningsSar: 0,
      statusLabelKey: 'cancelled',
    ),
    DeliveryHistoryItem(
      id: 'hist-004',
      storeName: 'Merchant Delta',
      pickupLabel: 'Pickup Central',
      dropoffLabel: 'Dropoff Harbor',
      completedAt: DateTime.utc(2026, 7, 23, 11, 40),
      earningsSar: 31.25,
      statusLabelKey: 'delivered',
    ),
  ];

  factory FakeDeliveryHistoryRepository.forApp() {
    return FakeDeliveryHistoryRepository(
      isProductionEnvironment: () => AppConfig.isProduction,
    );
  }

  @override
  Future<List<DeliveryHistoryItem>> listHistory({
    DeliveryHistoryFilter filter = DeliveryHistoryFilter.all,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return switch (filter) {
      DeliveryHistoryFilter.all => List.unmodifiable(_items),
      DeliveryHistoryFilter.delivered => List.unmodifiable(
        _items.where((e) => e.statusLabelKey == 'delivered'),
      ),
      DeliveryHistoryFilter.cancelled => List.unmodifiable(
        _items.where((e) => e.statusLabelKey == 'cancelled'),
      ),
    };
  }

  @override
  Future<DeliveryHistoryItem?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

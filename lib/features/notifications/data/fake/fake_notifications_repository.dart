import '../../../../core/config/app_config.dart';
import '../../domain/entities/driver_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    required bool Function() isProductionEnvironment,
    List<DriverNotification>? seed,
  }) : _items = List.of(seed ?? _defaultSeed) {
    if (isProductionEnvironment()) {
      throw StateError(
        'FakeNotificationsRepository must not be constructed in production.',
      );
    }
  }

  final List<DriverNotification> _items;

  static final _defaultSeed = <DriverNotification>[
    DriverNotification(
      id: 'notif-001',
      titleKey: 'offer',
      bodyKey: 'offer_body',
      createdAt: DateTime.utc(2026, 7, 26, 9, 0),
      isRead: false,
    ),
    DriverNotification(
      id: 'notif-002',
      titleKey: 'payout',
      bodyKey: 'payout_body',
      createdAt: DateTime.utc(2026, 7, 25, 18, 0),
      isRead: false,
    ),
    DriverNotification(
      id: 'notif-003',
      titleKey: 'system',
      bodyKey: 'system_body',
      createdAt: DateTime.utc(2026, 7, 24, 12, 0),
      isRead: true,
    ),
  ];

  factory FakeNotificationsRepository.forApp() {
    return FakeNotificationsRepository(
      isProductionEnvironment: () => AppConfig.isProduction,
    );
  }

  @override
  Future<List<DriverNotification>> listNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final sorted = List<DriverNotification>.of(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<DriverNotification?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<DriverNotification?> markRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final updated = _items[index].copyWith(isRead: true);
    _items[index] = updated;
    return updated;
  }

  @override
  Future<int> unreadCount() async {
    return _items.where((e) => !e.isRead).length;
  }
}

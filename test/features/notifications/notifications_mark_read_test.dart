import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/notifications/data/fake/fake_notifications_repository.dart';
import 'package:saeq_driver/features/notifications/domain/entities/driver_notification.dart';
import 'package:saeq_driver/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saeq_driver/features/notifications/presentation/providers/notifications_providers.dart';

class _FailingMarkReadRepo implements NotificationsRepository {
  _FailingMarkReadRepo(this._inner);

  final FakeNotificationsRepository _inner;

  @override
  Future<DriverNotification?> getById(String id) => _inner.getById(id);

  @override
  Future<List<DriverNotification>> listNotifications() =>
      _inner.listNotifications();

  @override
  Future<DriverNotification?> markRead(String id) async {
    throw StateError('mark_read_forced_failure');
  }

  @override
  Future<int> unreadCount() => _inner.unreadCount();
}

void main() {
  group('NotificationsController markRead', () {
    test('successful markRead updates list and detail provider', () async {
      final repo = FakeNotificationsRepository(
        isProductionEnvironment: () => false,
      );
      final container = ProviderContainer(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(notificationsControllerProvider.notifier).load();
      final before = container.read(notificationsControllerProvider);
      expect(
        before.items.firstWhere((e) => e.id == 'notif-001').isRead,
        isFalse,
      );

      final detailBefore = await container.read(
        notificationDetailProvider('notif-001').future,
      );
      expect(detailBefore!.isRead, isFalse);

      await container
          .read(notificationsControllerProvider.notifier)
          .markRead('notif-001');

      final after = container.read(notificationsControllerProvider);
      expect(after.failureMessage, isNull);
      expect(after.items.firstWhere((e) => e.id == 'notif-001').isRead, isTrue);

      final detailAfter = await container.read(
        notificationDetailProvider('notif-001').future,
      );
      expect(detailAfter!.isRead, isTrue);
    });

    test('repository failure preserves unread and sets failure', () async {
      final inner = FakeNotificationsRepository(
        isProductionEnvironment: () => false,
      );
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            _FailingMarkReadRepo(inner),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsControllerProvider.notifier).load();
      final unreadBefore = container
          .read(notificationsControllerProvider)
          .unreadCount;

      await container
          .read(notificationsControllerProvider.notifier)
          .markRead('notif-001');

      final after = container.read(notificationsControllerProvider);
      expect(after.failureMessage, 'mark_read_failed');
      expect(after.unreadCount, unreadBefore);
      expect(
        after.items.firstWhere((e) => e.id == 'notif-001').isRead,
        isFalse,
      );
    });

    test('repeated markRead is safe', () async {
      final repo = FakeNotificationsRepository(
        isProductionEnvironment: () => false,
      );
      final container = ProviderContainer(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        notificationsControllerProvider.notifier,
      );
      await controller.load();
      await controller.markRead('notif-001');
      await controller.markRead('notif-001');

      final after = container.read(notificationsControllerProvider);
      expect(after.failureMessage, isNull);
      expect(after.items.firstWhere((e) => e.id == 'notif-001').isRead, isTrue);
    });
  });

  group('FakeNotificationsRepository guards', () {
    test('production construction throws', () {
      expect(
        () => FakeNotificationsRepository(isProductionEnvironment: () => true),
        throwsStateError,
      );
    });
  });
}

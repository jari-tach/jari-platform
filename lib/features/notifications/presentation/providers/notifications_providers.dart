import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../data/fake/fake_notifications_repository.dart';
import '../../domain/entities/driver_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository?>((
  ref,
) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {}
  return FakeNotificationsRepository.forApp();
});

class NotificationsControllerState {
  const NotificationsControllerState({
    this.items = const [],
    this.loading = false,
    this.failureMessage,
  });

  final List<DriverNotification> items;
  final bool loading;
  final String? failureMessage;

  int get unreadCount => items.where((e) => !e.isRead).length;

  NotificationsControllerState copyWith({
    List<DriverNotification>? items,
    bool? loading,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return NotificationsControllerState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      failureMessage: clearFailure
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}

class NotificationsController extends Notifier<NotificationsControllerState> {
  @override
  NotificationsControllerState build() {
    Future.microtask(load);
    return const NotificationsControllerState(loading: true);
  }

  NotificationsRepository? get _repo =>
      ref.read(notificationsRepositoryProvider);

  Future<void> load() async {
    final repo = _repo;
    if (repo == null) {
      state = const NotificationsControllerState(
        failureMessage: 'unavailable',
        loading: false,
      );
      return;
    }
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final items = await repo.listNotifications();
      if (!ref.mounted) return;
      state = state.copyWith(items: items, loading: false);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, failureMessage: 'load_failed');
    }
  }

  /// Marks [id] read after successful repository persistence only.
  ///
  /// On success: reloads the list and invalidates [notificationDetailProvider]
  /// so detail cannot show a stale unread state.
  /// On failure: keeps the previous list/unread state and sets [failureMessage].
  Future<void> markRead(String id) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      await repo.markRead(id);
      if (!ref.mounted) return;
      await load();
      if (!ref.mounted) return;
      ref.invalidate(notificationDetailProvider(id));
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(failureMessage: 'mark_read_failed');
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsControllerState>(
      NotificationsController.new,
    );

final notificationDetailProvider =
    FutureProvider.family<DriverNotification?, String>((ref, id) async {
      final repo = ref.watch(notificationsRepositoryProvider);
      if (repo == null) return null;
      return repo.getById(id);
    });

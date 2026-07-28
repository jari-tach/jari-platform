import '../entities/driver_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<DriverNotification>> listNotifications();

  Future<DriverNotification?> getById(String id);

  Future<DriverNotification?> markRead(String id);

  Future<int> unreadCount();
}

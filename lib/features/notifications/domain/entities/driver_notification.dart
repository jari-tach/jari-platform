/// In-app notification (Fake Alpha).
class DriverNotification {
  const DriverNotification({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final DateTime createdAt;
  final bool isRead;

  DriverNotification copyWith({bool? isRead}) {
    return DriverNotification(
      id: id,
      titleKey: titleKey,
      bodyKey: bodyKey,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

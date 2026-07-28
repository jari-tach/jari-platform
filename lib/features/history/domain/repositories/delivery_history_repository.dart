import '../entities/delivery_history_item.dart';

abstract interface class DeliveryHistoryRepository {
  Future<List<DeliveryHistoryItem>> listHistory({
    DeliveryHistoryFilter filter = DeliveryHistoryFilter.all,
  });

  Future<DeliveryHistoryItem?> getById(String id);
}

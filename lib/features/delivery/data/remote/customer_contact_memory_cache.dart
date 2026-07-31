import '../models/delivery_lifecycle_wire.dart';

/// In-memory-only customer contact cache (STEP 5C-3).
///
/// Never persists to Drift, SharedPreferences, files, logs, or analytics.
final class CustomerContactMemoryCache {
  CustomerContactWire? _current;

  CustomerContactWire? get current => _current;

  void set(CustomerContactWire contact) {
    _current = contact;
  }

  void clear() {
    _current = null;
  }

  /// Clears when [deliveryId] matches the cached contact (or always if null).
  void clearForDelivery(String? deliveryId) {
    if (deliveryId == null || _current?.deliveryId == deliveryId) {
      _current = null;
    }
  }
}

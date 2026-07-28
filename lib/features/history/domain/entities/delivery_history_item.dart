/// Completed delivery history item (**Fake Alpha — PHASE 2.6 Inc 3**).
///
/// Seeded independently of the approved live delivery workflow. This is **not**
/// derived from real completed assignments until an explicit later design.
///
/// [earningsSar] uses `double` for Fake UI only. Production money must use
/// integer minor units or an approved decimal type — not this field.
class DeliveryHistoryItem {
  const DeliveryHistoryItem({
    required this.id,
    required this.storeName,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.completedAt,
    required this.earningsSar,
    required this.statusLabelKey,
  });

  final String id;
  final String storeName;
  final String pickupLabel;
  final String dropoffLabel;
  final DateTime completedAt;

  /// Fake Alpha display amount only — not settlement-grade.
  final double earningsSar;

  /// Stable key: delivered | cancelled.
  final String statusLabelKey;
}

/// Filter for history list.
enum DeliveryHistoryFilter { all, delivered, cancelled }

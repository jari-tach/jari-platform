import '../../domain/entities/delivery_order.dart';

/// Data-layer DTO for [DeliveryOrder] (PHASE 2.5).
///
/// No business rules — serialization and mapping only.
class DeliveryOrderModel {
  /// Creates an immutable order model.
  const DeliveryOrderModel({
    required this.orderId,
    required this.pickupLabel,
    required this.dropoffLabel,
    this.merchantDisplayName,
    this.distanceMeters,
    this.etaMinutes,
    this.notes,
  });

  final String orderId;
  final String pickupLabel;
  final String dropoffLabel;
  final String? merchantDisplayName;
  final double? distanceMeters;
  final int? etaMinutes;
  final String? notes;

  /// Maps a domain entity to this model.
  factory DeliveryOrderModel.fromEntity(DeliveryOrder entity) {
    return DeliveryOrderModel(
      orderId: entity.orderId,
      pickupLabel: entity.pickupLabel,
      dropoffLabel: entity.dropoffLabel,
      merchantDisplayName: entity.merchantDisplayName,
      distanceMeters: entity.distanceMeters,
      etaMinutes: entity.etaMinutes,
      notes: entity.notes,
    );
  }

  /// Maps this model to a domain entity.
  DeliveryOrder toEntity() {
    return DeliveryOrder(
      orderId: orderId,
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      merchantDisplayName: merchantDisplayName,
      distanceMeters: distanceMeters,
      etaMinutes: etaMinutes,
      notes: notes,
    );
  }

  /// Parses JSON into a model.
  ///
  /// Throws [FormatException] when required fields are missing or invalid.
  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    final pickupLabel = json['pickupLabel'];
    final dropoffLabel = json['dropoffLabel'];
    if (orderId is! String || orderId.trim().isEmpty) {
      throw const FormatException('orderId missing or invalid');
    }
    if (pickupLabel is! String) {
      throw const FormatException('pickupLabel missing or invalid');
    }
    if (dropoffLabel is! String) {
      throw const FormatException('dropoffLabel missing or invalid');
    }

    final distance = json['distanceMeters'];
    final eta = json['etaMinutes'];
    return DeliveryOrderModel(
      orderId: orderId,
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      merchantDisplayName: json['merchantDisplayName'] as String?,
      distanceMeters: distance == null
          ? null
          : (distance is num
                ? distance.toDouble()
                : throw const FormatException('distanceMeters invalid')),
      etaMinutes: eta == null
          ? null
          : (eta is int
                ? eta
                : (eta is num
                      ? eta.toInt()
                      : throw const FormatException('etaMinutes invalid'))),
      notes: json['notes'] as String?,
    );
  }

  /// Serializes this model to JSON.
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'pickupLabel': pickupLabel,
    'dropoffLabel': dropoffLabel,
    'merchantDisplayName': merchantDisplayName,
    'distanceMeters': distanceMeters,
    'etaMinutes': etaMinutes,
    'notes': notes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOrderModel &&
          orderId == other.orderId &&
          pickupLabel == other.pickupLabel &&
          dropoffLabel == other.dropoffLabel &&
          merchantDisplayName == other.merchantDisplayName &&
          distanceMeters == other.distanceMeters &&
          etaMinutes == other.etaMinutes &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    orderId,
    pickupLabel,
    dropoffLabel,
    merchantDisplayName,
    distanceMeters,
    etaMinutes,
    notes,
  );
}

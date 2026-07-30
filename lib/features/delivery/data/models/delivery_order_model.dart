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
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
  });

  final String orderId;
  final String pickupLabel;
  final String dropoffLabel;
  final String? merchantDisplayName;
  final double? distanceMeters;
  final int? etaMinutes;
  final String? notes;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;

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
      pickupLatitude: entity.pickupLatitude,
      pickupLongitude: entity.pickupLongitude,
      dropoffLatitude: entity.dropoffLatitude,
      dropoffLongitude: entity.dropoffLongitude,
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
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropoffLatitude: dropoffLatitude,
      dropoffLongitude: dropoffLongitude,
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
      pickupLatitude: _optionalDouble(json['pickupLatitude'], 'pickupLatitude'),
      pickupLongitude: _optionalDouble(
        json['pickupLongitude'],
        'pickupLongitude',
      ),
      dropoffLatitude: _optionalDouble(
        json['dropoffLatitude'],
        'dropoffLatitude',
      ),
      dropoffLongitude: _optionalDouble(
        json['dropoffLongitude'],
        'dropoffLongitude',
      ),
    );
  }

  static double? _optionalDouble(Object? value, String field) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw FormatException('$field invalid');
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
    if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
    if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
    if (dropoffLatitude != null) 'dropoffLatitude': dropoffLatitude,
    if (dropoffLongitude != null) 'dropoffLongitude': dropoffLongitude,
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
          notes == other.notes &&
          pickupLatitude == other.pickupLatitude &&
          pickupLongitude == other.pickupLongitude &&
          dropoffLatitude == other.dropoffLatitude &&
          dropoffLongitude == other.dropoffLongitude;

  @override
  int get hashCode => Object.hash(
    orderId,
    pickupLabel,
    dropoffLabel,
    merchantDisplayName,
    distanceMeters,
    etaMinutes,
    notes,
    pickupLatitude,
    pickupLongitude,
    dropoffLatitude,
    dropoffLongitude,
  );
}

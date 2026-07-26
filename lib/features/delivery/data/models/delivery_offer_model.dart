import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/delivery_offer_status.dart';
import 'delivery_order_model.dart';

/// Data-layer DTO for [DeliveryOffer] (PHASE 2.5).
///
/// No business rules — serialization and mapping only.
class DeliveryOfferModel {
  /// Creates an immutable offer model.
  const DeliveryOfferModel({
    required this.offerId,
    required this.driverId,
    required this.status,
    required this.order,
    required this.issuedAt,
    required this.expiresAt,
    this.revision,
    this.correlationId,
  });

  final String offerId;
  final String driverId;
  final String status;
  final DeliveryOrderModel order;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? revision;
  final String? correlationId;

  /// Maps a domain entity to this model.
  factory DeliveryOfferModel.fromEntity(DeliveryOffer entity) {
    return DeliveryOfferModel(
      offerId: entity.offerId,
      driverId: entity.driverId,
      status: entity.status.name,
      order: DeliveryOrderModel.fromEntity(entity.order),
      issuedAt: entity.issuedAt.toUtc(),
      expiresAt: entity.expiresAt.toUtc(),
      revision: entity.revision,
      correlationId: entity.correlationId,
    );
  }

  /// Maps this model to a domain entity.
  ///
  /// Throws [FormatException] when [status] is unknown.
  DeliveryOffer toEntity() {
    return DeliveryOffer(
      offerId: offerId,
      driverId: driverId,
      status: _parseOfferStatus(status),
      order: order.toEntity(),
      issuedAt: issuedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      revision: revision,
      correlationId: correlationId,
    );
  }

  /// Parses JSON into a model.
  ///
  /// Throws [FormatException] when required fields are missing or invalid.
  factory DeliveryOfferModel.fromJson(Map<String, dynamic> json) {
    final offerId = json['offerId'];
    final driverId = json['driverId'];
    final status = json['status'];
    final orderRaw = json['order'];
    final issuedAtRaw = json['issuedAt'];
    final expiresAtRaw = json['expiresAt'];

    if (offerId is! String || offerId.trim().isEmpty) {
      throw const FormatException('offerId missing or invalid');
    }
    if (driverId is! String || driverId.trim().isEmpty) {
      throw const FormatException('driverId missing or invalid');
    }
    if (status is! String || status.trim().isEmpty) {
      throw const FormatException('status missing or invalid');
    }
    if (orderRaw is! Map) {
      throw const FormatException('order missing or invalid');
    }
    if (issuedAtRaw is! String) {
      throw const FormatException('issuedAt missing or invalid');
    }
    if (expiresAtRaw is! String) {
      throw const FormatException('expiresAt missing or invalid');
    }

    final issuedAt = DateTime.tryParse(issuedAtRaw);
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (issuedAt == null || expiresAt == null) {
      throw const FormatException('issuedAt/expiresAt must be ISO-8601');
    }

    return DeliveryOfferModel(
      offerId: offerId,
      driverId: driverId,
      status: status,
      order: DeliveryOrderModel.fromJson(Map<String, dynamic>.from(orderRaw)),
      issuedAt: issuedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      revision: json['revision'] as String?,
      correlationId: json['correlationId'] as String?,
    );
  }

  /// Serializes this model to JSON.
  Map<String, dynamic> toJson() => {
    'offerId': offerId,
    'driverId': driverId,
    'status': status,
    'order': order.toJson(),
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'revision': revision,
    'correlationId': correlationId,
  };

  static DeliveryOfferStatus _parseOfferStatus(String raw) {
    for (final value in DeliveryOfferStatus.values) {
      if (value.name == raw) return value;
    }
    throw FormatException('unknown offer status: $raw');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOfferModel &&
          offerId == other.offerId &&
          driverId == other.driverId &&
          status == other.status &&
          order == other.order &&
          issuedAt == other.issuedAt &&
          expiresAt == other.expiresAt &&
          revision == other.revision &&
          correlationId == other.correlationId;

  @override
  int get hashCode => Object.hash(
    offerId,
    driverId,
    status,
    order,
    issuedAt,
    expiresAt,
    revision,
    correlationId,
  );
}

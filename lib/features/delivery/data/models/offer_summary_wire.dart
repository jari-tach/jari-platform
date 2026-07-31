/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
library;

import 'delivery_offer_model.dart';
import 'delivery_order_model.dart';

final class OfferSummaryWire {
  const OfferSummaryWire({
    required this.offerId,
    required this.status,
    required this.estimatedDistanceMeters,
    required this.estimatedDurationSeconds,
    required this.compensationAmount,
    required this.compensationCurrency,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.expiresAt,
    required this.aggregateVersion,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  final String offerId;
  final String status;
  final int estimatedDistanceMeters;
  final int estimatedDurationSeconds;
  final num compensationAmount;
  final String compensationCurrency;
  final String pickupLabel;
  final String dropoffLabel;
  final DateTime expiresAt;
  final int aggregateVersion;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  factory OfferSummaryWire.fromJson(Map<String, dynamic> json) {
    final offerId = json['offerId'];
    final status = json['status'];
    final distance = json['estimatedDistanceMeters'];
    final duration = json['estimatedDurationSeconds'];
    final compensation = json['compensation'];
    final pickup = json['pickup'];
    final dropoff = json['dropoff'];
    final expiresAtRaw = json['expiresAt'];
    final version = json['aggregateVersion'];
    if (offerId is! String ||
        status is! String ||
        distance is! int ||
        duration is! int ||
        compensation is! Map ||
        pickup is! Map ||
        dropoff is! Map ||
        expiresAtRaw is! String ||
        version is! int) {
      throw const FormatException('OfferSummaryWire: invalid fields');
    }
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      throw const FormatException('OfferSummaryWire: expiresAt');
    }
    final amount = compensation['amount'];
    final currency = compensation['currency'];
    if (amount is! num || currency is! String) {
      throw const FormatException('OfferSummaryWire: compensation');
    }
    final pickupLabel = pickup['label'];
    final dropoffLabel = dropoff['label'];
    if (pickupLabel is! String || dropoffLabel is! String) {
      throw const FormatException('OfferSummaryWire: stops');
    }
    final pickupLoc = pickup['location'];
    final dropoffLoc = dropoff['location'];
    return OfferSummaryWire(
      offerId: offerId,
      status: status,
      estimatedDistanceMeters: distance,
      estimatedDurationSeconds: duration,
      compensationAmount: amount,
      compensationCurrency: currency,
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      expiresAt: expiresAt,
      aggregateVersion: version,
      pickupLat: _lat(pickupLoc),
      pickupLng: _lng(pickupLoc),
      dropoffLat: _lat(dropoffLoc),
      dropoffLng: _lng(dropoffLoc),
    );
  }

  static double? _lat(Object? loc) {
    if (loc is! Map) return null;
    final v = loc['latitude'] ?? loc['lat'];
    return v is num ? v.toDouble() : null;
  }

  static double? _lng(Object? loc) {
    if (loc is! Map) return null;
    final v = loc['longitude'] ?? loc['lng'];
    return v is num ? v.toDouble() : null;
  }

  DeliveryOfferModel toDeliveryOfferModel({required String driverId}) {
    return DeliveryOfferModel(
      offerId: offerId,
      driverId: driverId,
      status: status,
      order: DeliveryOrderModel(
        orderId: offerId,
        pickupLabel: pickupLabel,
        dropoffLabel: dropoffLabel,
        distanceMeters: estimatedDistanceMeters.toDouble(),
        etaMinutes: (estimatedDurationSeconds / 60).ceil(),
        pickupLatitude: pickupLat,
        pickupLongitude: pickupLng,
        dropoffLatitude: dropoffLat,
        dropoffLongitude: dropoffLng,
        notes: '$compensationAmount $compensationCurrency',
      ),
      issuedAt: DateTime.now().toUtc(),
      expiresAt: expiresAt.toUtc(),
      revision: '$aggregateVersion',
    );
  }
}

final class OfferActionResponseWire {
  const OfferActionResponseWire({
    required this.offerId,
    required this.deliveryId,
    required this.state,
    required this.aggregateVersion,
  });

  final String offerId;
  final String deliveryId;
  final String state;
  final int aggregateVersion;

  factory OfferActionResponseWire.fromJson(Map<String, dynamic> json) {
    final offerId = json['offerId'];
    final deliveryId = json['deliveryId'];
    final state = json['state'];
    final version = json['aggregateVersion'];
    if (offerId is! String ||
        deliveryId is! String ||
        state is! String ||
        version is! int) {
      throw const FormatException('OfferActionResponseWire');
    }
    return OfferActionResponseWire(
      offerId: offerId,
      deliveryId: deliveryId,
      state: state,
      aggregateVersion: version,
    );
  }
}

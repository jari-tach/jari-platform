import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_order.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';

/// Shared deterministic fixtures for PHASE 2.5 delivery tests.
final deliveryIssuedAt = DateTime.utc(2026, 7, 26, 10);
final deliveryExpiresAt = DateTime.utc(2026, 7, 26, 10, 2);
final deliveryAcceptedAt = DateTime.utc(2026, 7, 26, 10, 1);

DeliveryOrder sampleOrder({
  String orderId = 'ord-1',
  String pickupLabel = 'Pickup A',
  String dropoffLabel = 'Dropoff B',
  String? merchantDisplayName = 'Merchant',
  double? distanceMeters = 1200,
  int? etaMinutes = 15,
  String? notes = 'ring bell',
}) => DeliveryOrder(
  orderId: orderId,
  pickupLabel: pickupLabel,
  dropoffLabel: dropoffLabel,
  merchantDisplayName: merchantDisplayName,
  distanceMeters: distanceMeters,
  etaMinutes: etaMinutes,
  notes: notes,
);

DeliveryOffer sampleOffer({
  String offerId = 'off-1',
  String driverId = 'drv-1',
  DeliveryOfferStatus status = DeliveryOfferStatus.offered,
  DeliveryOrder? order,
  DateTime? issuedAt,
  DateTime? expiresAt,
  String? revision = 'rev-1',
  String? correlationId = 'corr-1',
}) => DeliveryOffer(
  offerId: offerId,
  driverId: driverId,
  status: status,
  order: order ?? sampleOrder(),
  issuedAt: issuedAt ?? deliveryIssuedAt,
  expiresAt: expiresAt ?? deliveryExpiresAt,
  revision: revision,
  correlationId: correlationId,
);

DeliveryAssignment sampleAssignment({
  String assignmentId = 'asg-1',
  String offerId = 'off-1',
  String driverId = 'drv-1',
  DeliveryStatus status = DeliveryStatus.accepted,
  DeliveryOrder? order,
  DateTime? acceptedAt,
  String? serverRevision = 'srev-1',
}) => DeliveryAssignment(
  assignmentId: assignmentId,
  offerId: offerId,
  driverId: driverId,
  status: status,
  order: order ?? sampleOrder(),
  acceptedAt: acceptedAt ?? deliveryAcceptedAt,
  serverRevision: serverRevision,
);

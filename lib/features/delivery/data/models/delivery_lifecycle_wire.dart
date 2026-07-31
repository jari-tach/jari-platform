/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
library;

final class CustomerContactWire {
  const CustomerContactWire({
    required this.deliveryId,
    required this.name,
    required this.phoneNumber,
    required this.availableUntil,
  });

  final String deliveryId;
  final String name;
  final String phoneNumber;
  final DateTime availableUntil;

  factory CustomerContactWire.fromJson(Map<String, dynamic> json) {
    final deliveryId = json['deliveryId'];
    final name = json['name'];
    final phoneNumber = json['phoneNumber'];
    final availableUntilRaw = json['availableUntil'];
    if (deliveryId is! String ||
        name is! String ||
        phoneNumber is! String ||
        availableUntilRaw is! String) {
      throw const FormatException('CustomerContactWire');
    }
    final availableUntil = DateTime.tryParse(availableUntilRaw);
    if (availableUntil == null) {
      throw const FormatException('CustomerContactWire: availableUntil');
    }
    return CustomerContactWire(
      deliveryId: deliveryId,
      name: name,
      phoneNumber: phoneNumber,
      availableUntil: availableUntil,
    );
  }
}

final class DeliveryMutationResponseWire {
  const DeliveryMutationResponseWire({
    required this.deliveryId,
    required this.state,
    required this.aggregateVersion,
    required this.updatedAt,
  });

  final String deliveryId;
  final String state;
  final int aggregateVersion;
  final DateTime updatedAt;

  factory DeliveryMutationResponseWire.fromJson(Map<String, dynamic> json) {
    final deliveryId = json['deliveryId'];
    final state = json['state'];
    final version = json['aggregateVersion'];
    final updatedAtRaw = json['updatedAt'];
    if (deliveryId is! String ||
        state is! String ||
        version is! int ||
        updatedAtRaw is! String) {
      throw const FormatException('DeliveryMutationResponseWire');
    }
    final updatedAt = DateTime.tryParse(updatedAtRaw);
    if (updatedAt == null) {
      throw const FormatException('DeliveryMutationResponseWire: updatedAt');
    }
    return DeliveryMutationResponseWire(
      deliveryId: deliveryId,
      state: state,
      aggregateVersion: version,
      updatedAt: updatedAt,
    );
  }
}

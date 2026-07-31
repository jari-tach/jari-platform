/// Memory-only customer contact for the current delivery (STEP 5D-1).
///
/// PII: never persist this entity to Drift, SharedPreferences, files, logs,
/// analytics, or crash reports. [toString] is intentionally redacted.
final class CustomerContact {
  const CustomerContact({
    required this.deliveryId,
    required this.name,
    required this.phoneNumber,
    required this.availableUntil,
  });

  final String deliveryId;
  final String name;
  final String phoneNumber;
  final DateTime availableUntil;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerContact &&
          deliveryId == other.deliveryId &&
          name == other.name &&
          phoneNumber == other.phoneNumber &&
          availableUntil == other.availableUntil;

  @override
  int get hashCode =>
      Object.hash(deliveryId, name, phoneNumber, availableUntil);

  @override
  String toString() => 'CustomerContact(deliveryId: $deliveryId, <redacted>)';
}

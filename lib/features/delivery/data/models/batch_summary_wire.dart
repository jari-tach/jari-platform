/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
library;

final class BatchSummaryWire {
  const BatchSummaryWire({
    required this.batchId,
    required this.currentStopSequence,
    required this.stops,
    required this.aggregateVersion,
  });

  final String batchId;
  final int currentStopSequence;
  final List<BatchStopWire> stops;
  final int aggregateVersion;

  factory BatchSummaryWire.fromJson(Map<String, dynamic> json) {
    final batchId = json['batchId'];
    final current = json['currentStopSequence'] ?? json['currentStop'];
    final stopsRaw = json['stops'] ?? json['upcomingStops'];
    final version = json['aggregateVersion'];
    if (batchId is! String || version is! int) {
      throw const FormatException('BatchSummaryWire');
    }
    final sequence = current is int
        ? current
        : (current is Map && current['sequence'] is int
              ? current['sequence'] as int
              : 1);
    final stopsList = stopsRaw is List ? stopsRaw : const [];
    return BatchSummaryWire(
      batchId: batchId,
      currentStopSequence: sequence,
      aggregateVersion: version,
      stops: stopsList
          .map(
            (e) => BatchStopWire.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  /// Upcoming stops must never expose customer contact fields.
  bool get upcomingStopsHaveContactFields => stops.any(
    (s) =>
        s.sequence > currentStopSequence && (s.hasPhoneField || s.hasNameField),
  );
}

final class BatchStopWire {
  const BatchStopWire({
    required this.sequence,
    required this.deliveryId,
    required this.stopType,
    required this.label,
    this.hasPhoneField = false,
    this.hasNameField = false,
  });

  final int sequence;
  final String deliveryId;
  final String stopType;
  final String label;
  final bool hasPhoneField;
  final bool hasNameField;

  factory BatchStopWire.fromJson(Map<String, dynamic> json) {
    final sequence = json['sequence'];
    final deliveryId = json['deliveryId'];
    final stopType = json['stopType'];
    final label = json['label'];
    if (sequence is! int ||
        deliveryId is! String ||
        stopType is! String ||
        label is! String) {
      throw const FormatException('BatchStopWire');
    }
    return BatchStopWire(
      sequence: sequence,
      deliveryId: deliveryId,
      stopType: stopType,
      label: label,
      hasPhoneField:
          json.containsKey('phoneNumber') || json.containsKey('phone'),
      hasNameField:
          json.containsKey('customerName') || json.containsKey('name'),
    );
  }
}

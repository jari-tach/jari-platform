/// Domain view of an active delivery batch (STEP 5D-1).
///
/// Stops never carry customer contact fields — upcoming-customer PII is
/// rejected at the data boundary before this entity is built.
final class BatchSummary {
  BatchSummary({
    required this.batchId,
    required this.currentStopSequence,
    required List<BatchStop> stops,
    required this.aggregateVersion,
  }) : stops = List<BatchStop>.unmodifiable(stops);

  final String batchId;
  final int currentStopSequence;
  final List<BatchStop> stops;
  final int aggregateVersion;

  BatchStop? get currentStop {
    for (final stop in stops) {
      if (stop.sequence == currentStopSequence) return stop;
    }
    return null;
  }

  int get totalStops => stops.length;
}

/// A single batch stop without any customer contact data.
final class BatchStop {
  const BatchStop({
    required this.sequence,
    required this.deliveryId,
    required this.stopType,
    required this.label,
  });

  final int sequence;
  final String deliveryId;
  final String stopType;
  final String label;
}

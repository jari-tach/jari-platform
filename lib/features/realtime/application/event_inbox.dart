// ignore_for_file: prefer_initializing_formals

import '../domain/entities/driver_event.dart';

/// Result of attempting to accept an event into the local inbox.
enum EventInboxDecision {
  /// New event — process side effects and advance the cursor.
  accepted,

  /// Duplicate `eventId` or `sequence` already seen.
  duplicate,

  /// Sequence not strictly greater than the last accepted sequence.
  staleSequence,

  /// Same aggregate already has a higher or equal `aggregateVersion`.
  staleAggregate,

  /// Event does not belong to the bound driver session.
  foreignDriver,
}

/// Deduplicates and orders realtime events for one driver session.
///
/// Rules (STEP 6-B):
/// - Drop duplicates by `eventId` and by `sequence`.
/// - Require strictly increasing `sequence` relative to the last accepted.
/// - Per-aggregate `aggregateVersion` must be strictly greater than known.
/// - Events whose payload / aggregateId clearly belong to another driver
///   are rejected when [boundDriverId] is set.
final class EventInbox {
  EventInbox({String? boundDriverId, int initialSequence = 0})
    : _boundDriverId = boundDriverId,
      _lastSequence = initialSequence;

  String? _boundDriverId;
  int _lastSequence;
  final Set<String> _seenEventIds = <String>{};
  final Set<int> _seenSequences = <int>{};
  final Map<String, int> _aggregateVersions = <String, int>{};

  int get lastSequence => _lastSequence;
  String? get boundDriverId => _boundDriverId;

  void bindDriver(String driverId) {
    final trimmed = driverId.trim();
    if (_boundDriverId != null && _boundDriverId != trimmed) {
      reset(boundDriverId: trimmed);
      return;
    }
    _boundDriverId = trimmed;
  }

  void reset({String? boundDriverId, int initialSequence = 0}) {
    _boundDriverId = boundDriverId?.trim();
    _lastSequence = initialSequence;
    _seenEventIds.clear();
    _seenSequences.clear();
    _aggregateVersions.clear();
  }

  /// Advances the resume cursor for unknown/ignored wire events without
  /// applying aggregate side effects.
  void noteSequence(int sequence) {
    if (sequence > _lastSequence) {
      _lastSequence = sequence;
    }
  }

  EventInboxDecision accept(DriverEvent event) {
    if (_seenEventIds.contains(event.eventId) ||
        _seenSequences.contains(event.sequence)) {
      return EventInboxDecision.duplicate;
    }
    if (event.sequence <= _lastSequence) {
      return EventInboxDecision.staleSequence;
    }

    final bound = _boundDriverId;
    if (bound != null && bound.isNotEmpty) {
      final payloadDriver = event.payload['driverId'];
      if (payloadDriver is String &&
          payloadDriver.isNotEmpty &&
          payloadDriver != bound) {
        return EventInboxDecision.foreignDriver;
      }
      if (event.aggregateType == 'driver' && event.aggregateId != bound) {
        return EventInboxDecision.foreignDriver;
      }
    }

    final aggregateKey = '${event.aggregateType}:${event.aggregateId}';
    final known = _aggregateVersions[aggregateKey];
    if (known != null && event.aggregateVersion <= known) {
      // Still advance sequence cursor so we do not re-fetch forever, but
      // refuse to apply the stale aggregate mutation.
      _seenEventIds.add(event.eventId);
      _seenSequences.add(event.sequence);
      _lastSequence = event.sequence;
      _trimSeen();
      return EventInboxDecision.staleAggregate;
    }

    _seenEventIds.add(event.eventId);
    _seenSequences.add(event.sequence);
    _lastSequence = event.sequence;
    _aggregateVersions[aggregateKey] = event.aggregateVersion;
    _trimSeen();
    return EventInboxDecision.accepted;
  }

  void _trimSeen() {
    // Bound memory: keep a sliding window of recent ids/sequences.
    const maxSeen = 256;
    if (_seenEventIds.length > maxSeen) {
      final drop = _seenEventIds.length - maxSeen;
      final doomed = _seenEventIds.take(drop).toList(growable: false);
      _seenEventIds.removeAll(doomed);
    }
    if (_seenSequences.length > maxSeen) {
      final sorted = _seenSequences.toList()..sort();
      final drop = sorted.length - maxSeen;
      _seenSequences.removeAll(sorted.take(drop));
    }
  }
}

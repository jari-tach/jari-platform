import 'dart:async';

import 'package:saeq_driver/features/realtime/data/models/event_envelope_wire.dart';
import 'package:saeq_driver/features/realtime/data/models/event_page_wire.dart';
import 'package:saeq_driver/features/realtime/data/remote/driver_events_remote.dart';
import 'package:saeq_driver/features/realtime/data/remote/sse_transport.dart';

/// Controllable events remote for STEP 6-B unit/integration tests.
final class FakeDriverEventsRemote implements DriverEventsRemote {
  final List<EventEnvelopeWire> polledEvents = <EventEnvelopeWire>[];
  final List<int?> pollAfterCalls = <int?>[];
  final List<int?> streamLastEventIds = <int?>[];

  int streamOpenCount = 0;
  int closeCount = 0;
  bool failNextSse = false;
  Object sseFailure = const SseTransportException('sse down');
  bool pollFails = false;
  bool resyncRequired = false;
  EventPageWire Function(int? after)? pollHandler;

  StreamController<EventEnvelopeWire>? _sseController;
  Completer<void>? _sseHold;

  @override
  Future<EventPageWire> listEvents({int? after, int limit = 50}) async {
    pollAfterCalls.add(after);
    if (pollFails) {
      throw StateError('poll failed');
    }
    if (pollHandler != null) {
      return pollHandler!(after);
    }
    final events = polledEvents
        .where((e) => after == null || e.sequence > after)
        .toList(growable: false);
    final latest = events.isEmpty
        ? (after ?? 0)
        : events.map((e) => e.sequence).reduce((a, b) => a > b ? a : b);
    return EventPageWire(
      events: events,
      latestSequence: latest,
      hasMore: false,
      resyncRequired: resyncRequired,
    );
  }

  @override
  Stream<EventEnvelopeWire> streamEvents({int? lastEventId}) {
    streamLastEventIds.add(lastEventId);
    streamOpenCount += 1;
    if (failNextSse) {
      return Stream<EventEnvelopeWire>.error(sseFailure);
    }
    final controller = StreamController<EventEnvelopeWire>();
    _sseController = controller;
    _sseHold = Completer<void>();
    controller.onCancel = () {
      if (!(_sseHold?.isCompleted ?? true)) {
        _sseHold!.complete();
      }
    };
    return controller.stream;
  }

  void emitSse(EventEnvelopeWire wire) {
    final controller = _sseController;
    if (controller == null || controller.isClosed) {
      throw StateError('SSE stream is not open');
    }
    controller.add(wire);
  }

  void failSse([Object? error]) {
    final controller = _sseController;
    if (controller == null || controller.isClosed) {
      throw StateError('SSE stream is not open');
    }
    controller.addError(error ?? sseFailure);
  }

  Future<void> completeSse() async {
    final controller = _sseController;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  @override
  Future<void> closeStream() async {
    closeCount += 1;
    final controller = _sseController;
    _sseController = null;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    if (!(_sseHold?.isCompleted ?? true)) {
      _sseHold!.complete();
    }
  }
}

EventEnvelopeWire sampleEnvelope({
  String eventId = '00000000-0000-4000-8000-000000000050',
  int sequence = 1,
  String eventType = 'offer.created',
  String aggregateType = 'offer',
  String aggregateId = '00000000-0000-4000-8000-000000000010',
  int aggregateVersion = 1,
  Map<String, Object?> payload = const {'offerId': 'offer-1'},
}) {
  return EventEnvelopeWire(
    eventId: eventId,
    sequence: sequence,
    eventType: eventType,
    occurredAt: DateTime.utc(2026, 7, 31, 12),
    aggregateType: aggregateType,
    aggregateId: aggregateId,
    aggregateVersion: aggregateVersion,
    correlationId: '00000000-0000-4000-8000-000000000002',
    payloadVersion: 1,
    payload: payload,
  );
}

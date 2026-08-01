import '../models/event_envelope_wire.dart';
import '../models/event_page_wire.dart';

/// Contract events channel: polling page + SSE stream (STEP 6-B).
abstract interface class DriverEventsRemote {
  Future<EventPageWire> listEvents({int? after, int limit = 50});

  Stream<EventEnvelopeWire> streamEvents({int? lastEventId});

  Future<void> closeStream();
}

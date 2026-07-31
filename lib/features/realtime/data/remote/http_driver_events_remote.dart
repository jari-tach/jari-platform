// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import '../../../../core/backend_configuration/driver_api_paths.dart';
import '../../../../core/auth_session/access_token_memory_cache.dart';
import '../../../../core/network/request_id_factory.dart';
import '../../../../core/network/saeq_api_client.dart';
import '../models/event_envelope_wire.dart';
import '../models/event_page_wire.dart';
import 'driver_events_remote.dart';
import 'sse_transport.dart';

/// Remote access to contracts-v0.2.0 events channel (polling + SSE frames).
final class HttpDriverEventsRemote implements DriverEventsRemote {
  HttpDriverEventsRemote({
    required SaeqApiClient api,
    required String baseUrl,
    required AccessTokenMemoryCache accessTokenCache,
    required SseTransport sseTransport,
    RequestIdFactory? requestIdFactory,
  }) : _api = api,
       _baseUrl = _normalizeBaseUrl(baseUrl),
       _accessTokenCache = accessTokenCache,
       _sse = sseTransport,
       _requestIdFactory = requestIdFactory ?? RequestIdFactory();

  final SaeqApiClient _api;
  final String _baseUrl;
  final AccessTokenMemoryCache _accessTokenCache;
  final SseTransport _sse;
  final RequestIdFactory _requestIdFactory;

  static String _normalizeBaseUrl(String raw) {
    if (raw.endsWith('/')) return raw.substring(0, raw.length - 1);
    return raw;
  }

  /// `GET /v1/events?after=&limit=` — polling fallback / catch-up.
  @override
  Future<EventPageWire> listEvents({int? after, int limit = 50}) async {
    final query = <String, dynamic>{
      'limit': limit.clamp(1, 50),
      if (after != null && after >= 0) 'after': after,
    };
    final response = await _api.get<Map<String, dynamic>>(
      DriverApiPaths.events,
      queryParameters: query,
    );
    final Object? raw = response.data;
    if (raw is! Map) {
      throw const FormatException('EventPage is not an object');
    }
    return EventPageWire.fromJson(Map<String, dynamic>.from(raw));
  }

  /// Opens `GET /v1/events/stream` and yields parsed envelopes.
  ///
  /// Keep-alive comments never yield. Malformed data frames are skipped.
  /// Throws [SseUnauthorizedException] on 401 so the coordinator can
  /// attempt a single token refresh.
  @override
  Stream<EventEnvelopeWire> streamEvents({int? lastEventId}) {
    final token = _accessTokenCache.accessToken;
    if (token == null || token.isEmpty) {
      return Stream.error(
        const SseUnauthorizedException('Missing access token'),
      );
    }

    final url = Uri.parse('$_baseUrl${DriverApiPaths.eventsStream}');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-Request-Id': _requestIdFactory.next(),
      'Accept': 'text/event-stream',
    };

    return _sse
        .connect(
          url: url,
          headers: headers,
          lastEventId: lastEventId?.toString(),
        )
        .transform(
          StreamTransformer<SseFrame, EventEnvelopeWire>.fromHandlers(
            handleData: (frame, sink) {
              try {
                final decoded = jsonDecode(frame.data);
                if (decoded is! Map) return;
                sink.add(
                  EventEnvelopeWire.fromJson(
                    Map<String, dynamic>.from(decoded),
                  ),
                );
              } on FormatException {
                // Malformed frame — skip without killing the stream.
              } on Object {
                // jsonDecode errors — skip.
              }
            },
          ),
        );
  }

  @override
  Future<void> closeStream() => _sse.close();
}

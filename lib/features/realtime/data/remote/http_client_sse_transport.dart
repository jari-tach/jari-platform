import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'sse_transport.dart';

/// Production SSE transport over [HttpClient] (mobile/desktop).
///
/// Keep-alive comment frames (`:` lines) are ignored — they never surface
/// as functional events. `Last-Event-ID` is sent when [lastEventId] is set.
final class HttpClientSseTransport implements SseTransport {
  HttpClientSseTransport({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;
  HttpClientRequest? _activeRequest;
  StreamSubscription<List<int>>? _subscription;
  bool _closed = false;

  @override
  Stream<SseFrame> connect({
    required Uri url,
    required Map<String, String> headers,
    String? lastEventId,
  }) {
    final controller = StreamController<SseFrame>();

    () async {
      try {
        await close();
        _closed = false;
        final request = await _httpClient.getUrl(url);
        _activeRequest = request;
        headers.forEach(request.headers.set);
        request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
        if (lastEventId != null && lastEventId.isNotEmpty) {
          request.headers.set('Last-Event-ID', lastEventId);
        }

        final response = await request.close();
        if (_closed) {
          await response.drain<void>();
          return;
        }
        if (response.statusCode == 401) {
          if (!controller.isClosed) {
            controller.addError(
              const SseUnauthorizedException('SSE unauthorized'),
            );
            await controller.close();
          }
          return;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (!controller.isClosed) {
            controller.addError(
              SseTransportException('SSE HTTP ${response.statusCode}'),
            );
            await controller.close();
          }
          return;
        }

        final parser = _SseParser();
        _subscription = response.listen(
          (chunk) {
            for (final frame in parser.add(utf8.decode(chunk))) {
              if (!controller.isClosed) controller.add(frame);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) {
              controller.addError(error, stack);
              unawaited(controller.close());
            }
          },
          onDone: () {
            for (final frame in parser.flush()) {
              if (!controller.isClosed) controller.add(frame);
            }
            if (!controller.isClosed) unawaited(controller.close());
          },
          cancelOnError: true,
        );
      } catch (error, stack) {
        if (!controller.isClosed) {
          controller.addError(error, stack);
          await controller.close();
        }
      }
    }();

    controller.onCancel = () {
      unawaited(close());
    };
    return controller.stream;
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
    try {
      _activeRequest?.abort();
    } catch (_) {
      // Request may already be closed.
    }
    _activeRequest = null;
  }
}

/// Incremental SSE parser (WHATWG-style field accumulation).
final class _SseParser {
  final StringBuffer _buffer = StringBuffer();
  String? _id;
  String? _event;
  final StringBuffer _data = StringBuffer();

  List<SseFrame> add(String chunk) {
    _buffer.write(chunk);
    final frames = <SseFrame>[];
    while (true) {
      final text = _buffer.toString();
      final nl = text.indexOf('\n');
      if (nl < 0) break;
      var line = text.substring(0, nl);
      _buffer
        ..clear()
        ..write(text.substring(nl + 1));
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      final frame = _consumeLine(line);
      if (frame != null) frames.add(frame);
    }
    return frames;
  }

  List<SseFrame> flush() {
    final frames = <SseFrame>[];
    final trailing = _buffer.toString();
    _buffer.clear();
    if (trailing.isNotEmpty) {
      final frame = _consumeLine(trailing);
      if (frame != null) frames.add(frame);
    }
    final pending = _emitIfReady(force: true);
    if (pending != null) frames.add(pending);
    return frames;
  }

  SseFrame? _consumeLine(String line) {
    if (line.isEmpty) {
      return _emitIfReady();
    }
    if (line.startsWith(':')) {
      // Keep-alive / comment — ignore.
      return null;
    }
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);

    switch (field) {
      case 'id':
        _id = value;
      case 'event':
        _event = value;
      case 'data':
        if (_data.isNotEmpty) _data.write('\n');
        _data.write(value);
      default:
        break;
    }
    return null;
  }

  SseFrame? _emitIfReady({bool force = false}) {
    if (_data.isEmpty && !force) {
      _id = null;
      _event = null;
      return null;
    }
    if (_data.isEmpty) return null;
    final frame = SseFrame(id: _id, event: _event, data: _data.toString());
    _id = null;
    _event = null;
    _data.clear();
    return frame;
  }
}

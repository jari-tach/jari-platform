/// One Server-Sent Events frame. Comment/keep-alive frames are never emitted.
final class SseFrame {
  const SseFrame({this.id, this.event, required this.data});

  final String? id;
  final String? event;
  final String data;
}

/// Injectable SSE transport so unit/integration tests can fake the stream.
abstract interface class SseTransport {
  /// Opens an SSE connection. Emits data frames only; keep-alive comments
  /// are consumed silently. Completes/errors when the socket closes.
  Stream<SseFrame> connect({
    required Uri url,
    required Map<String, String> headers,
    String? lastEventId,
  });

  /// Cancels any in-flight connection.
  Future<void> close();
}

final class SseUnauthorizedException implements Exception {
  const SseUnauthorizedException(this.message);
  final String message;
  @override
  String toString() => 'SseUnauthorizedException($message)';
}

final class SseTransportException implements Exception {
  const SseTransportException(this.message);
  final String message;
  @override
  String toString() => 'SseTransportException($message)';
}

import 'uuid_v4.dart';

/// Creates `X-Request-Id` values (UUID).
final class RequestIdFactory {
  RequestIdFactory({UuidV4? uuid}) : _uuid = uuid ?? UuidV4();

  final UuidV4 _uuid;

  String next() => _uuid.next();
}

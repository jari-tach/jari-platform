import 'uuid_v4.dart';

/// Creates `Idempotency-Key` values matching contracts-v0.1.0
/// (8–128 chars, pattern `^[A-Za-z0-9._~-]+$`).
final class IdempotencyKeyFactory {
  IdempotencyKeyFactory({UuidV4? uuid}) : _uuid = uuid ?? UuidV4();

  final UuidV4 _uuid;

  String next() => _uuid.next();
}

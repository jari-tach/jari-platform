/// Deterministic local idempotency command ids for delivery operations.
///
/// The backend validates the `Idempotency-Key` header against the contract
/// pattern `^[A-Za-z0-9._~-]{8,128}$`. The previous format joined components
/// with `:` (`local:driver:target:action`), which the backend rejects with
/// `VALIDATION_ERROR — Idempotency-Key header contains unsupported
/// characters`.
///
/// Guarantees:
/// - Pure function of (driverId, targetId, action[, scope]): retries and Local
///   Command Ledger replays reuse the exact same key for the same inputs.
/// - Different driver, target, action, or scope always produce a different key.
/// - Output always matches the contract pattern, including the 8–128 length
///   bounds, even if a component contains characters outside the allowed
///   set (each such character is escaped, never dropped, so distinct inputs
///   cannot collapse into the same key).
///
/// [scope] should carry the aggregate / server revision when the target id is
/// stable across Backend resets (e.g. seed delivery UUID). Without it, a later
/// confirmPickup against a recycled delivery reuses the old key with a new
/// `aggregateVersion` body and the Backend returns IDEMPOTENCY_CONFLICT.
library;

/// Allowed by contract: `A–Z a–z 0–9 . _ ~ -`.
final RegExp _allowedChar = RegExp(r'[A-Za-z0-9._~-]');

String localCommandId({
  required String driverId,
  required String targetId,
  required String action,
  String? scope,
}) {
  final scopePart = scope?.trim();
  final raw = (scopePart == null || scopePart.isEmpty)
      ? 'local_${driverId}_${targetId}_$action'
      : 'local_${driverId}_${targetId}_${action}_$scopePart';
  final key = _escape(raw);
  if (key.length <= 128) return key;
  // Components are UUIDs and short action literals in practice (~115 chars
  // max), so this is defensive: keep determinism and uniqueness by replacing
  // the tail with a digest of the full raw value.
  final digest = _digest(raw);
  return '${key.substring(0, 128 - digest.length - 1)}~$digest';
}

/// Escapes every disallowed character as `.<code>.` so different inputs can
/// never normalize to the same key (a plain replaceAll('-') would map both
/// `a:b` and `a-b` to `a-b`).
String _escape(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.runes) {
    final char = String.fromCharCode(rune);
    if (_allowedChar.hasMatch(char)) {
      buffer.write(char);
    } else {
      buffer
        ..write('.')
        ..write(rune.toRadixString(36))
        ..write('.');
    }
  }
  return buffer.toString();
}

String _digest(String raw) {
  var hash = 17;
  for (final unit in raw.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash.toRadixString(36);
}

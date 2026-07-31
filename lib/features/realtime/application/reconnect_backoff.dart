import 'dart:math';

/// Exponential backoff with full jitter for realtime reconnects.
final class ReconnectBackoff {
  ReconnectBackoff({
    this.initial = const Duration(seconds: 1),
    this.maximum = const Duration(seconds: 30),
    this.multiplier = 2.0,
    Random? random,
  }) : _random = random ?? Random();

  final Duration initial;
  final Duration maximum;
  final double multiplier;
  final Random _random;

  int _attempt = 0;

  int get attempt => _attempt;

  void reset() => _attempt = 0;

  /// Returns the next delay and advances the attempt counter.
  Duration next() {
    final exp = initial.inMilliseconds * pow(multiplier, _attempt);
    final capped = min(exp, maximum.inMilliseconds.toDouble());
    _attempt += 1;
    // Full jitter: uniform in [0, capped].
    final ms = (_random.nextDouble() * capped).round();
    return Duration(milliseconds: max(ms, initial.inMilliseconds ~/ 4));
  }
}

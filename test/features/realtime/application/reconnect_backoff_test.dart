import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/realtime/application/reconnect_backoff.dart';

void main() {
  group('ReconnectBackoff', () {
    test('grows with jitter and respects maximum', () {
      final backoff = ReconnectBackoff(
        initial: const Duration(milliseconds: 100),
        maximum: const Duration(milliseconds: 800),
        multiplier: 2,
        random: Random(7),
      );

      final delays = List<Duration>.generate(8, (_) => backoff.next());
      expect(delays.first.inMilliseconds, lessThanOrEqualTo(100));
      expect(delays.every((d) => d.inMilliseconds <= 800), isTrue);
      expect(backoff.attempt, 8);
    });

    test('reset restarts the attempt counter', () {
      final backoff = ReconnectBackoff(
        initial: const Duration(seconds: 1),
        maximum: const Duration(seconds: 30),
        random: Random(1),
      );
      backoff.next();
      backoff.next();
      expect(backoff.attempt, 2);
      backoff.reset();
      expect(backoff.attempt, 0);
    });
  });
}

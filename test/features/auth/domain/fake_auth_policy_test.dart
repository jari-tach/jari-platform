import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/domain/policies/fake_auth_policy.dart';

void main() {
  group('FakeAuthPolicy', () {
    test('allows debug/non-production with empty reason codes', () {
      final decision = FakeAuthPolicy.evaluate(
        isReleaseMode: false,
        isProductionEnvironment: false,
      );
      expect(decision.allowed, isTrue);
      expect(decision.reasonCodes, isEmpty);
      expect(decision.policyVersion, FakeAuthPolicy.policyVersion);
    });

    test('denies production with exact reason code', () {
      final decision = FakeAuthPolicy.evaluate(
        isReleaseMode: false,
        isProductionEnvironment: true,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reasonCodes, [
        FakeAuthReasonCode.productionEnvironmentDenied,
      ]);
    });

    test('denies release even when environment claims non-production', () {
      final decision = FakeAuthPolicy.evaluate(
        isReleaseMode: true,
        isProductionEnvironment: false,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reasonCodes, [FakeAuthReasonCode.releaseModeDenied]);
    });

    test('collects multiple denial reasons for release+production', () {
      final decision = FakeAuthPolicy.evaluate(
        isReleaseMode: true,
        isProductionEnvironment: true,
      );
      expect(decision.allowed, isFalse);
      expect(decision.reasonCodes, [
        FakeAuthReasonCode.releaseModeDenied,
        FakeAuthReasonCode.productionEnvironmentDenied,
      ]);
    });

    test('invalid/unknown configuration defaults to deny', () {
      final cases = <({bool? release, bool? production})>[
        (release: null, production: false),
        (release: false, production: null),
        (release: null, production: null),
      ];

      for (final c in cases) {
        final decision = FakeAuthPolicy.evaluate(
          isReleaseMode: c.release,
          isProductionEnvironment: c.production,
        );
        expect(decision.allowed, isFalse, reason: '$c');
        expect(
          decision.reasonCodes,
          containsAll([
            FakeAuthReasonCode.invalidEnvironment,
            FakeAuthReasonCode.policyConfigurationMissing,
          ]),
        );
      }
    });

    test('table-driven decision matrix', () {
      final rows = <(bool?, bool?, bool, List<String>)>[
        (false, false, true, const []),
        (
          false,
          true,
          false,
          const [FakeAuthReasonCode.productionEnvironmentDenied],
        ),
        (true, false, false, const [FakeAuthReasonCode.releaseModeDenied]),
        (
          true,
          true,
          false,
          const [
            FakeAuthReasonCode.releaseModeDenied,
            FakeAuthReasonCode.productionEnvironmentDenied,
          ],
        ),
      ];

      for (final row in rows) {
        final decision = FakeAuthPolicy.evaluate(
          isReleaseMode: row.$1,
          isProductionEnvironment: row.$2,
        );
        expect(decision.allowed, row.$3, reason: '$row');
        expect(decision.reasonCodes, row.$4, reason: '$row');
      }
    });
  });
}

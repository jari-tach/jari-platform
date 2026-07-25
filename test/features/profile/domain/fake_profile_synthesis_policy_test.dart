import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/profile/domain/policies/fake_profile_synthesis_policy.dart';

void main() {
  group('FakeProfileSynthesisPolicy', () {
    test('allows non-production trial synthesis', () {
      final decision = FakeProfileSynthesisPolicy.evaluate(
        isReleaseMode: false,
        isProductionEnvironment: false,
      );
      expect(decision.allowed, isTrue);
      expect(decision.reasonCodes, isEmpty);
      expect(decision.policyVersion, FakeProfileSynthesisPolicy.policyVersion);
    });

    test('denies production with typed reasons', () {
      final decision = FakeProfileSynthesisPolicy.evaluate(
        isReleaseMode: false,
        isProductionEnvironment: true,
      );
      expect(decision.allowed, isFalse);
      expect(
        decision.reasonCodes,
        contains(FakeProfileSynthesisReasonCode.productionEnvironmentDenied),
      );
      expect(
        decision.reasonCodes,
        contains(FakeProfileSynthesisReasonCode.synthesisNotPermitted),
      );
    });

    test('denies release always', () {
      final decision = FakeProfileSynthesisPolicy.evaluate(
        isReleaseMode: true,
        isProductionEnvironment: false,
      );
      expect(decision.allowed, isFalse);
      expect(
        decision.reasonCodes,
        contains(FakeProfileSynthesisReasonCode.releaseModeDenied),
      );
      expect(
        decision.reasonCodes,
        contains(FakeProfileSynthesisReasonCode.synthesisNotPermitted),
      );
    });

    test('invalid environment defaults to deny', () {
      final decision = FakeProfileSynthesisPolicy.evaluate(
        isReleaseMode: null,
        isProductionEnvironment: null,
      );
      expect(decision.allowed, isFalse);
      expect(
        decision.reasonCodes,
        containsAll([
          FakeProfileSynthesisReasonCode.invalidEnvironment,
          FakeProfileSynthesisReasonCode.policyConfigurationMissing,
          FakeProfileSynthesisReasonCode.synthesisNotPermitted,
        ]),
      );
    });
  });
}

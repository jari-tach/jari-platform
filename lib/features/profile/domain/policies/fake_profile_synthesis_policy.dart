import '../../../../core/security/security_policy_decision.dart';

/// Typed reason codes for [FakeProfileSynthesisPolicy] (PHASE 2.3).
abstract final class FakeProfileSynthesisReasonCode {
  static const releaseModeDenied = 'releaseModeDenied';
  static const productionEnvironmentDenied = 'productionEnvironmentDenied';
  static const synthesisNotPermitted = 'synthesisNotPermitted';
  static const invalidEnvironment = 'invalidEnvironment';
  static const policyConfigurationMissing = 'policyConfigurationMissing';
}

/// Whether a trial/fake driver profile may be synthesized locally.
///
/// Production and Release must never invent a driver identity. Missing
/// profile → [ProfileNotFoundError] → controlled UI empty/error state.
///
/// Client-side only; Backend remains authoritative (BR-DRIVER-005 / BR-SEC-*).
class FakeProfileSynthesisPolicy {
  const FakeProfileSynthesisPolicy._();

  static const policyVersion = 'phase-2.3.profile-synthesis.v1';

  /// Full evaluation. Defaults to deny when inputs are null/unknown.
  static SecurityPolicyDecision evaluate({
    required bool? isReleaseMode,
    required bool? isProductionEnvironment,
  }) {
    if (isReleaseMode == null || isProductionEnvironment == null) {
      return SecurityPolicyDecision.deny(
        policyVersion: policyVersion,
        reasonCodes: const [
          FakeProfileSynthesisReasonCode.invalidEnvironment,
          FakeProfileSynthesisReasonCode.policyConfigurationMissing,
          FakeProfileSynthesisReasonCode.synthesisNotPermitted,
        ],
      );
    }

    final reasons = <String>[];
    if (isReleaseMode) {
      reasons.add(FakeProfileSynthesisReasonCode.releaseModeDenied);
    }
    if (isProductionEnvironment) {
      reasons.add(FakeProfileSynthesisReasonCode.productionEnvironmentDenied);
    }

    if (reasons.isNotEmpty) {
      if (!reasons.contains(
        FakeProfileSynthesisReasonCode.synthesisNotPermitted,
      )) {
        reasons.add(FakeProfileSynthesisReasonCode.synthesisNotPermitted);
      }
      return SecurityPolicyDecision.deny(
        policyVersion: policyVersion,
        reasonCodes: reasons,
      );
    }

    return SecurityPolicyDecision.allow(policyVersion: policyVersion);
  }

  static bool allowsTrialSynthesis({
    required bool? isReleaseMode,
    required bool? isProductionEnvironment,
  }) => evaluate(
    isReleaseMode: isReleaseMode,
    isProductionEnvironment: isProductionEnvironment,
  ).allowed;
}

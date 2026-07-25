import '../../../../core/security/security_policy_decision.dart';

/// Typed reason codes for [FakeAuthPolicy] (PHASE 2.3).
abstract final class FakeAuthReasonCode {
  static const releaseModeDenied = 'releaseModeDenied';
  static const productionEnvironmentDenied = 'productionEnvironmentDenied';
  static const invalidEnvironment = 'invalidEnvironment';
  static const policyConfigurationMissing = 'policyConfigurationMissing';
}

/// Environment policy for Fake Authentication (PHASE 2.3).
///
/// Pure, deterministic decision table. The concrete
/// [FakeAuthenticationRepository] **also** enforces a hard `kReleaseMode`
/// guard that cannot be disabled by Dart defines, remote config, or
/// constructor overrides.
class FakeAuthPolicy {
  const FakeAuthPolicy._();

  /// Policy version for auditability of decisions.
  static const policyVersion = 'phase-2.3.fake-auth.v1';

  /// Full evaluation. Defaults to deny when inputs are null/unknown.
  static SecurityPolicyDecision evaluate({
    required bool? isReleaseMode,
    required bool? isProductionEnvironment,
  }) {
    if (isReleaseMode == null || isProductionEnvironment == null) {
      return SecurityPolicyDecision.deny(
        policyVersion: policyVersion,
        reasonCodes: const [
          FakeAuthReasonCode.invalidEnvironment,
          FakeAuthReasonCode.policyConfigurationMissing,
        ],
      );
    }

    final reasons = <String>[];
    if (isReleaseMode) {
      reasons.add(FakeAuthReasonCode.releaseModeDenied);
    }
    if (isProductionEnvironment) {
      reasons.add(FakeAuthReasonCode.productionEnvironmentDenied);
    }

    if (reasons.isNotEmpty) {
      return SecurityPolicyDecision.deny(
        policyVersion: policyVersion,
        reasonCodes: reasons,
      );
    }

    return SecurityPolicyDecision.allow(policyVersion: policyVersion);
  }

  /// Convenience: `true` only when Fake Auth is allowed.
  static bool allowsFakeAuth({
    required bool? isReleaseMode,
    required bool? isProductionEnvironment,
  }) => evaluate(
    isReleaseMode: isReleaseMode,
    isProductionEnvironment: isProductionEnvironment,
  ).allowed;

  /// Inverse of [allowsFakeAuth].
  static bool blocksFakeAuth({
    required bool? isReleaseMode,
    required bool? isProductionEnvironment,
  }) => !allowsFakeAuth(
    isReleaseMode: isReleaseMode,
    isProductionEnvironment: isProductionEnvironment,
  );
}

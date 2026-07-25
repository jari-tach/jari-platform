/// Pure policy evaluation result (PHASE 2.3 security controls).
///
/// Side-effect free. No clocks, network, or storage. Default stance is deny
/// unless [allowed] is explicitly true.
class SecurityPolicyDecision {
  const SecurityPolicyDecision({
    required this.allowed,
    required this.reasonCodes,
    required this.policyVersion,
  });

  factory SecurityPolicyDecision.allow({
    required String policyVersion,
    List<String> reasonCodes = const [],
  }) => SecurityPolicyDecision(
    allowed: true,
    reasonCodes: List.unmodifiable(reasonCodes),
    policyVersion: policyVersion,
  );

  factory SecurityPolicyDecision.deny({
    required String policyVersion,
    required List<String> reasonCodes,
  }) => SecurityPolicyDecision(
    allowed: false,
    reasonCodes: List.unmodifiable(reasonCodes),
    policyVersion: policyVersion,
  );

  final bool allowed;
  final List<String> reasonCodes;
  final String policyVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityPolicyDecision &&
          allowed == other.allowed &&
          policyVersion == other.policyVersion &&
          _listEquals(reasonCodes, other.reasonCodes);

  @override
  int get hashCode =>
      Object.hash(allowed, policyVersion, Object.hashAll(reasonCodes));

  @override
  String toString() =>
      'SecurityPolicyDecision(allowed: $allowed, '
      'reasonCodes: $reasonCodes, policyVersion: $policyVersion)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
final class OtpChallengeWire {
  const OtpChallengeWire({
    required this.challengeId,
    required this.expiresAt,
    this.resendAvailableAt,
  });

  final String challengeId;
  final DateTime expiresAt;
  final DateTime? resendAvailableAt;

  factory OtpChallengeWire.fromJson(Map<String, dynamic> json) {
    final challengeId = json['challengeId'];
    final expiresAtRaw = json['expiresAt'];
    if (challengeId is! String || challengeId.isEmpty) {
      throw const FormatException('OtpChallengeWire: challengeId');
    }
    if (expiresAtRaw is! String) {
      throw const FormatException('OtpChallengeWire: expiresAt');
    }
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      throw const FormatException('OtpChallengeWire: expiresAt parse');
    }
    DateTime? resendAvailableAt;
    final resendRaw = json['resendAvailableAt'];
    if (resendRaw is String) {
      resendAvailableAt = DateTime.tryParse(resendRaw);
    }
    return OtpChallengeWire(
      challengeId: challengeId,
      expiresAt: expiresAt,
      resendAvailableAt: resendAvailableAt,
    );
  }
}

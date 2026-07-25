/// A trial/mock driver session (PHASE 2.2 — Authentication Foundation).
///
/// Deliberately minimal: only the fields routing and the fake sign-in flow
/// actually need. This is NOT a production session model — `sessionToken`
/// is a locally-generated trial token, never a real JWT or backend-issued
/// credential (see `FakeAuthenticationRepository`).
class DriverSession {
  const DriverSession({
    required this.driverId,
    required this.phoneNumber,
    required this.sessionToken,
    this.expiresAt,
  });

  /// Stable trial identifier for the signed-in driver.
  final String driverId;

  /// The phone number used to sign in. Never logged in full (see
  /// `maskedPhoneNumber`).
  final String phoneNumber;

  /// Opaque trial session token. NOT a production JWT/access token and must
  /// never be logged in full.
  final String sessionToken;

  /// Optional trial expiry. When null, the session never expires on its own
  /// (still cleared explicitly on sign out).
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Phone number with all but the last 2 digits masked, safe for logs/UI.
  String get maskedPhoneNumber {
    if (phoneNumber.length <= 2) return '**';
    final visible = phoneNumber.substring(phoneNumber.length - 2);
    return '${'*' * (phoneNumber.length - 2)}$visible';
  }

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'phoneNumber': phoneNumber,
    'sessionToken': sessionToken,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  /// Strict decode: throws [FormatException] on any missing/invalid
  /// required field rather than silently returning a partially-valid
  /// session. Callers (see `AuthSessionStorage`) must treat that as a
  /// corrupted session, not a crash.
  factory DriverSession.fromJson(Map<String, dynamic> json) {
    final driverId = json['driverId'];
    final phoneNumber = json['phoneNumber'];
    final sessionToken = json['sessionToken'];

    if (driverId is! String || driverId.isEmpty) {
      throw const FormatException(
        'DriverSession: missing or invalid "driverId"',
      );
    }
    if (phoneNumber is! String || phoneNumber.isEmpty) {
      throw const FormatException(
        'DriverSession: missing or invalid "phoneNumber"',
      );
    }
    if (sessionToken is! String || sessionToken.isEmpty) {
      throw const FormatException(
        'DriverSession: missing or invalid "sessionToken"',
      );
    }

    DateTime? expiresAt;
    final expiresAtRaw = json['expiresAt'];
    if (expiresAtRaw != null) {
      if (expiresAtRaw is! String) {
        throw const FormatException('DriverSession: invalid "expiresAt" type');
      }
      expiresAt = DateTime.tryParse(expiresAtRaw);
      if (expiresAt == null) {
        throw const FormatException('DriverSession: invalid "expiresAt" value');
      }
    }

    return DriverSession(
      driverId: driverId,
      phoneNumber: phoneNumber,
      sessionToken: sessionToken,
      expiresAt: expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverSession &&
          driverId == other.driverId &&
          phoneNumber == other.phoneNumber &&
          sessionToken == other.sessionToken &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode =>
      Object.hash(driverId, phoneNumber, sessionToken, expiresAt);

  /// Deliberately omits [sessionToken] to keep it out of logs/crash reports.
  @override
  String toString() =>
      'DriverSession(driverId: $driverId, phoneNumber: $maskedPhoneNumber, '
      'expiresAt: $expiresAt)';
}

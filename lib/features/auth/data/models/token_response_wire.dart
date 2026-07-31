/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
final class TokenResponseWire {
  const TokenResponseWire({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.tokenType,
    required this.driver,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String tokenType;
  final DriverProfileWire driver;

  factory TokenResponseWire.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final tokenType = json['tokenType'];
    final accessExp = json['accessTokenExpiresAt'];
    final refreshExp = json['refreshTokenExpiresAt'];
    final driverRaw = json['driver'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('TokenResponseWire: accessToken');
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const FormatException('TokenResponseWire: refreshToken');
    }
    if (tokenType is! String || tokenType.isEmpty) {
      throw const FormatException('TokenResponseWire: tokenType');
    }
    if (accessExp is! String || refreshExp is! String) {
      throw const FormatException('TokenResponseWire: expiresAt');
    }
    if (driverRaw is! Map) {
      throw const FormatException('TokenResponseWire: driver');
    }

    final accessTokenExpiresAt = DateTime.tryParse(accessExp);
    final refreshTokenExpiresAt = DateTime.tryParse(refreshExp);
    if (accessTokenExpiresAt == null || refreshTokenExpiresAt == null) {
      throw const FormatException('TokenResponseWire: expiresAt parse');
    }

    return TokenResponseWire(
      accessToken: accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshToken: refreshToken,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      tokenType: tokenType,
      driver: DriverProfileWire.fromJson(Map<String, dynamic>.from(driverRaw)),
    );
  }
}

final class DriverProfileWire {
  const DriverProfileWire({
    required this.driverId,
    required this.displayName,
    required this.phoneMasked,
    required this.locale,
    required this.status,
  });

  final String driverId;
  final String displayName;
  final String phoneMasked;
  final String locale;
  final String status;

  factory DriverProfileWire.fromJson(Map<String, dynamic> json) {
    final driverId = json['driverId'];
    final displayName = json['displayName'];
    final phoneMasked = json['phoneMasked'];
    final locale = json['locale'];
    final status = json['status'];
    if (driverId is! String ||
        displayName is! String ||
        phoneMasked is! String ||
        locale is! String ||
        status is! String) {
      throw const FormatException('DriverProfileWire: invalid fields');
    }
    return DriverProfileWire(
      driverId: driverId,
      displayName: displayName,
      phoneMasked: phoneMasked,
      locale: locale,
      status: status,
    );
  }
}

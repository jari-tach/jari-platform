/// Support contact channels exposed by the platform (nullable until Backend).
class SupportConfig {
  const SupportConfig({this.phone, this.email, this.helpUrl});

  final String? phone;
  final String? email;
  final String? helpUrl;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasEmail => email != null && email!.trim().isNotEmpty;
  bool get hasHelpUrl => helpUrl != null && helpUrl!.trim().isNotEmpty;

  bool get hasAnyContact => hasPhone || hasEmail || hasHelpUrl;

  /// Empty/unavailable config — preferred Fake default (no invented contacts).
  static const unavailable = SupportConfig();
}

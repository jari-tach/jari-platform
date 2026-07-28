/// Normalizes Saudi mobile numbers to local `05XXXXXXXX` format.
///
/// Accepts trimmed local numbers and common international prefixes
/// (`+966`, `966`, `00966`). Returns `null` when the input cannot be
/// normalized to a valid Saudi mobile number.
String? normalizeSaudiPhoneNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  if (RegExp(r'^05\d{8}$').hasMatch(trimmed)) {
    return trimmed;
  }

  final compact = trimmed.replaceAll(RegExp(r'[\s-]'), '');

  final international = RegExp(r'^(\+|00)?966(5\d{8})$').firstMatch(compact);
  if (international != null) {
    return '0${international.group(2)!}';
  }

  return null;
}

/// Returns true when [input] can be normalized to `05XXXXXXXX`.
bool isValidSaudiPhoneInput(String input) =>
    normalizeSaudiPhoneNumber(input) != null;

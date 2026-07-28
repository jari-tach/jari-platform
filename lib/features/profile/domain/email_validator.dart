/// Optional email validation for driver profile edits.
///
/// Empty or whitespace-only input is treated as "no email" (valid).
library;

final RegExp _optionalEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Trims [raw]; returns `null` when empty after trim, otherwise the trimmed
/// value.
String? normalizeOptionalEmail(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Returns `true` when [raw] is empty/whitespace or matches a reasonable
/// email shape.
bool isValidOptionalEmail(String? raw) {
  final normalized = normalizeOptionalEmail(raw);
  if (normalized == null) return true;
  return _optionalEmailPattern.hasMatch(normalized);
}

/// Returns [invalidMessage] when [raw] is non-empty and invalid; otherwise
/// `null`.
String? validateOptionalEmail(String? raw, {required String invalidMessage}) {
  if (isValidOptionalEmail(raw)) return null;
  return invalidMessage;
}

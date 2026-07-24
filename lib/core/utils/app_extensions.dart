import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

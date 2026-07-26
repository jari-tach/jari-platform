/// Limited hard-coded-copy **regression** guard (PHASE 2.4.1).
///
/// Classification: limited regression guard — NOT a complete detector.
/// Manual review of presentation widgets remains mandatory (see
/// `docs/localization/localization-guidelines.md`).
///
/// This suite only asserts that a small set of retired hard-coded literals
/// do not return, and that the guidelines checklist document still exists.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hard-coded copy audit', () {
    test('presentation files no longer contain retired hard-coded literals', () {
      final checks = <({String path, List<String> forbidden})>[
        (
          path: 'lib/features/driver/presentation/welcome_screen.dart',
          forbidden: [
            'التركيز الآن على الأساسيات والهيكلية قبل إضافة الميزات التجارية.',
          ],
        ),
        (
          path: 'lib/core/routes/app_router.dart',
          forbidden: [
            "label: 'Home'",
            "label: 'Orders'",
            "label: 'Profile'",
            "label: 'Settings'",
            'Page not found:',
            'screen - Coming soon',
            "'Explore Architecture'",
          ],
        ),
        (
          path: 'lib/features/auth/presentation/screens/login_screen.dart',
          forbidden: ["isBusy ? '...' :"],
        ),
      ];

      for (final check in checks) {
        final file = File(check.path);
        expect(file.existsSync(), isTrue, reason: '${check.path} missing');
        final source = file.readAsStringSync();
        for (final fragment in check.forbidden) {
          expect(
            source.contains(fragment),
            isFalse,
            reason:
                '${check.path} still contains hard-coded fragment: $fragment',
          );
        }
      }
    });

    test('review checklist remains documented', () {
      final guidelines = File('docs/localization/localization-guidelines.md');
      expect(guidelines.existsSync(), isTrue);
      final text = guidelines.readAsStringSync();
      expect(text.contains('Hard-coded copy review checklist'), isTrue);
      expect(
        text.contains('No hard-coded user-visible application text'),
        isTrue,
      );
    });
  });
}

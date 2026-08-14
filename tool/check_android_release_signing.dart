// W5 / P0-04 — static checks for Android release-signing plumbing (no secrets).
//
// Exit 0 when gitignore + example + gradle fail-closed markers are present.
// Does not require a real keystore.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final root = Directory.current;
  final failures = <String>[];

  void requireFile(String relative, {String? mustContain}) {
    final file = File('${root.path}${Platform.pathSeparator}$relative');
    if (!file.existsSync()) {
      failures.add('missing $relative');
      return;
    }
    if (mustContain != null) {
      final text = file.readAsStringSync();
      if (!text.contains(mustContain)) {
        failures.add('$relative missing required marker: $mustContain');
      }
    }
  }

  void requireGitignore(List<String> needles) {
    final gi = File('${root.path}${Platform.pathSeparator}.gitignore');
    if (!gi.existsSync()) {
      failures.add('missing .gitignore');
      return;
    }
    final text = gi.readAsStringSync(encoding: utf8);
    for (final needle in needles) {
      if (!text.contains(needle)) {
        failures.add('.gitignore missing pattern: $needle');
      }
    }
  }

  requireFile(
    'android/key.properties.example',
    mustContain: 'replace-locally',
  );
  requireFile(
    'android/app/build.gradle.kts',
    mustContain: 'W5 release signing refused',
  );
  requireFile(
    'android/app/build.gradle.kts',
    mustContain: 'debug.keystore is forbidden',
  );
  // Must not wire debug signing into release.
  final gradle = File(
    '${root.path}${Platform.pathSeparator}android'
    '${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle.kts',
  );
  if (gradle.existsSync()) {
    final text = gradle.readAsStringSync();
    if (RegExp(
      r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
    ).hasMatch(text)) {
      failures.add('release still assigns debug signingConfig');
    }
  }

  requireGitignore(const [
    'key.properties',
    '*.jks',
    '*.keystore',
  ]);

  if (failures.isNotEmpty) {
    stderr.writeln('W5 Android signing gate FAILED:');
    for (final f in failures) {
      stderr.writeln(' - $f');
    }
    exit(1);
  }
  stdout.writeln('W5 Android signing gate PASS (static plumbing; no production keys).');
}

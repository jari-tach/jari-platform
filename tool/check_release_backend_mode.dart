import 'dart:io';

import 'package:saeq_driver/core/backend_configuration/backend_mode.dart';

/// Pure Dart CI gate (no Flutter foundation import).
void main(List<String> args) {
  final build = _arg(args, 'build');
  final mode = _arg(args, 'mode');
  final baseUrl = _arg(args, 'base-url') ?? '';

  if (build != null || mode != null) {
    final ok = _ok(
      build: build ?? 'release',
      mode: mode ?? '',
      baseUrl: baseUrl,
    );
    exit(ok ? 0 : 1);
  }

  final failures = <String>[];
  void check(String name, bool expectPass, void Function() run) {
    try {
      run();
      if (!expectPass) failures.add('$name expected FAIL');
    } catch (_) {
      if (expectPass) failures.add('$name expected PASS');
    }
  }

  check('release+remote', true, () {
    _resolve(
      mode: 'remote',
      release: true,
      profile: false,
      baseUrl: 'https://api.example.com',
    );
  });
  check('release+fake', false, () {
    _resolve(mode: 'fake', release: true, profile: false, baseUrl: '');
  });
  check('release+missing', false, () {
    _resolve(mode: '', release: true, profile: false, baseUrl: '');
  });
  check('release+unknown', false, () {
    _resolve(mode: 'hybrid', release: true, profile: false, baseUrl: '');
  });
  check('profile+fake', false, () {
    _resolve(mode: 'fake', release: false, profile: true, baseUrl: '');
  });

  if (failures.isNotEmpty) {
    stderr.writeln(failures.join('\n'));
    exit(1);
  }
  stdout.writeln('PASS: driver release backend mode matrix');
}

void _resolve({
  required String mode,
  required bool release,
  required bool profile,
  required String baseUrl,
}) {
  final parsed = BackendMode.parse(mode);
  if (parsed == BackendMode.fake && (release || profile)) {
    throw StateError('Fake not permitted in profile/release');
  }
  if (parsed == BackendMode.remote && baseUrl.trim().isEmpty) {
    throw StateError('URL required for remote');
  }
}

bool _ok({
  required String build,
  required String mode,
  required String baseUrl,
}) {
  try {
    _resolve(
      mode: mode,
      release: build == 'release',
      profile: build == 'profile',
      baseUrl: baseUrl.isEmpty && mode == 'remote'
          ? 'https://api.example.com'
          : baseUrl,
    );
    return true;
  } catch (_) {
    return false;
  }
}

String? _arg(List<String> args, String name) {
  final prefix = '--$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) return a.substring(prefix.length);
  }
  return null;
}

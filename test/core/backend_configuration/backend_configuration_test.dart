import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/backend_configuration.dart';
import 'package:saeq_driver/core/backend_configuration/backend_mode.dart';

void main() {
  group('BackendConfiguration', () {
    test('defaults to fake in debug/test', () {
      final config = BackendConfiguration.resolve(
        modeDefine: 'fake',
        baseUrlDefine: '',
        isReleaseMode: false,
        isProfileMode: false,
        isDebugMode: true,
      );
      expect(config.mode, BackendMode.fake);
      expect(config.isFake, isTrue);
    });

    test('remote requires base URL', () {
      expect(
        () => BackendConfiguration.resolve(
          modeDefine: 'remote',
          baseUrlDefine: '',
          isReleaseMode: false,
          isProfileMode: false,
          isDebugMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('remote accepts local base URL', () {
      final config = BackendConfiguration.resolve(
        modeDefine: 'remote',
        baseUrlDefine: 'http://127.0.0.1:3000/',
        isReleaseMode: false,
        isProfileMode: false,
        isDebugMode: true,
      );
      expect(config.isRemote, isTrue);
      expect(config.apiBaseUrl, 'http://127.0.0.1:3000');
    });

    test('production fake guard — release', () {
      expect(
        () => BackendConfiguration.resolve(
          modeDefine: 'fake',
          baseUrlDefine: '',
          isReleaseMode: true,
          isProfileMode: false,
          isDebugMode: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('production fake guard — profile', () {
      expect(
        () => BackendConfiguration.resolve(
          modeDefine: 'fake',
          baseUrlDefine: '',
          isReleaseMode: false,
          isProfileMode: true,
          isDebugMode: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('invalid mode throws', () {
      expect(
        () => BackendConfiguration.resolve(
          modeDefine: 'hybrid',
          baseUrlDefine: '',
          isReleaseMode: false,
          isProfileMode: false,
          isDebugMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

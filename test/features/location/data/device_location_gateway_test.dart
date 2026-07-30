import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/location/data/device_location_gateway.dart';
import 'package:saeq_driver/features/location/data/device_location_platform.dart';
import 'package:saeq_driver/features/location/data/location_gateway.dart';
import 'package:saeq_driver/features/location/domain/location_fix.dart';
import 'package:saeq_driver/features/location/domain/location_probe.dart';

void main() {
  final now = DateTime.utc(2026, 7, 30, 18);

  group('DeviceLocationGateway GNSS fallback policy', () {
    test('timeout + fresh accurate last-known is available fallback', () async {
      final platform = _FakeDeviceLocationPlatform(
        currentAttempts: [_timeout],
        lastKnown: _sample(now.subtract(const Duration(seconds: 20)), 12),
      );
      final result = await DeviceLocationGateway(
        platform: platform,
        clock: () => now,
      ).probeCurrent();

      expect(result.outcome, LocationProbeOutcome.available);
      expect(result.source, LocationSampleSource.lastKnown);
      expect(result.isFallback, isTrue);
      expect(result.capturedAt, now.subtract(const Duration(seconds: 20)));
      expect(platform.currentPrecisions, [DeviceLocationPrecision.high]);
      expect(result.outcome, isNot(LocationProbeOutcome.offline));
    });

    test(
      'timeout + stale last-known is stale after one medium retry',
      () async {
        final platform = _FakeDeviceLocationPlatform(
          currentAttempts: [_timeout, _timeout],
          lastKnown: _sample(now.subtract(const Duration(minutes: 5)), 12),
        );
        final result = await DeviceLocationGateway(
          platform: platform,
          clock: () => now,
        ).probeCurrent();

        expect(result.outcome, LocationProbeOutcome.stale);
        expect(result.source, LocationSampleSource.lastKnown);
        expect(platform.currentPrecisions, [
          DeviceLocationPrecision.high,
          DeviceLocationPrecision.medium,
        ]);
        expect(result.outcome, isNot(LocationProbeOutcome.offline));
      },
    );

    test('timeout + fresh low-accuracy last-known is weak accuracy', () async {
      final platform = _FakeDeviceLocationPlatform(
        currentAttempts: [_timeout],
        lastKnown: _sample(now.subtract(const Duration(seconds: 10)), 110),
      );
      final result = await DeviceLocationGateway(
        platform: platform,
        clock: () => now,
      ).probeCurrent();

      expect(result.outcome, LocationProbeOutcome.weakAccuracy);
      expect(result.accuracyMeters, 110);
      expect(result.source, LocationSampleSource.lastKnown);
      expect(result.outcome, isNot(LocationProbeOutcome.offline));
    });

    test(
      'platform exception without fallback is unavailable, not offline',
      () async {
        final platform = _FakeDeviceLocationPlatform(
          currentAttempts: [() async => throw StateError('platform')],
        );
        final result = await DeviceLocationGateway(
          platform: platform,
          clock: () => now,
        ).probeCurrent();

        expect(result.outcome, LocationProbeOutcome.unavailable);
        expect(result.outcome, isNot(LocationProbeOutcome.offline));
      },
    );
  });

  test('position stream survives silence and has no gateway timeout', () async {
    final platform = _FakeDeviceLocationPlatform();
    final gateway = DeviceLocationGateway(platform: platform, clock: () => now);
    final received = <LocationFix>[];
    final subscription = gateway.watchFixes().listen(received.add);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(received, isEmpty);
    platform.emit(_sample(now, 8));
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.recordedAt, now);
    expect(platform.watchCalls, 1);
    await subscription.cancel();
    await platform.close();
  });

  test('GNSS failure copy never blames internet or network', () {
    final ar = AppLocalizations(const Locale('ar'));
    final en = AppLocalizations(const Locale('en'));

    expect(ar.locationGnssUnavailableMessage, isNot(contains('الإنترنت')));
    expect(ar.locationStaleMessage, isNot(contains('الإنترنت')));
    expect(
      en.locationGnssUnavailableMessage.toLowerCase(),
      isNot(contains('network')),
    );
    expect(en.locationStaleMessage.toLowerCase(), isNot(contains('network')));
  });
}

Future<DevicePositionSample> _timeout() =>
    Future<DevicePositionSample>.error(TimeoutException('GNSS timeout'));

DevicePositionSample _sample(DateTime at, double accuracy) {
  return DevicePositionSample(
    latitude: 24.7136,
    longitude: 46.6753,
    accuracyMeters: accuracy,
    capturedAt: at,
  );
}

class _FakeDeviceLocationPlatform implements DeviceLocationPlatform {
  _FakeDeviceLocationPlatform({
    List<Future<DevicePositionSample> Function()>? currentAttempts,
    this.lastKnown,
  }) : _currentAttempts = [...?currentAttempts];

  final List<Future<DevicePositionSample> Function()> _currentAttempts;
  final DevicePositionSample? lastKnown;
  final currentPrecisions = <DeviceLocationPrecision>[];
  final _positions = StreamController<DevicePositionSample>.broadcast();
  int watchCalls = 0;

  void emit(DevicePositionSample sample) => _positions.add(sample);

  Future<void> close() => _positions.close();

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<DevicePositionSample> currentPosition({
    required DeviceLocationPrecision precision,
    required Duration timeout,
  }) {
    currentPrecisions.add(precision);
    if (_currentAttempts.isEmpty) {
      return Future<DevicePositionSample>.error(
        StateError('No current response configured'),
      );
    }
    return _currentAttempts.removeAt(0)();
  }

  @override
  Future<DevicePositionSample?> lastKnownPosition() async => lastKnown;

  @override
  Stream<DevicePositionSample> watchPositions() {
    watchCalls++;
    return _positions.stream;
  }
}

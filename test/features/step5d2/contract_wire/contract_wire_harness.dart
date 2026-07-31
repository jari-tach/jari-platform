/// STEP 5D-2 contract wire harness.
///
/// Wraps `SaeqApiClient` around a scripted `HttpClientAdapter` so tests can
/// assert the REAL outbound request (method, path, headers, body) and feed
/// contract-shaped (contracts-v0.1.0) responses back through the live client
/// stack, including interceptors and the 401 single-flight refresh path.
///
/// All fixtures use synthetic identifiers and synthetic `+9665xxxxxxx`-style
/// contact data — never real customer PII.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:saeq_driver/core/auth_session/access_token_memory_cache.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/core/network/saeq_api_client.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';

// ---------------------------------------------------------------------------
// Deterministic contract fixtures (synthetic UUIDs / UTC ISO-8601 instants).
// ---------------------------------------------------------------------------

const fixtureDriverId = '4f8a2c1e-9b3d-4e5f-8a6b-1c2d3e4f5a6b';
const fixtureOfferId = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const fixtureDeliveryId = '9b2fae3d-5c8e-4f21-b0a7-6d4e8c2a1f35';
const fixtureBatchId = '3e7d1c9a-2b4f-4a6e-9c8d-5f0a1b2c3d4e';
const fixtureChallengeId = '2f1e3d4c-5b6a-4978-8899-aabbccddeeff';
const fixtureRequestId = '6a5b4c3d-2e1f-4a0b-9c8d-7e6f5a4b3c2d';
const fixtureUpdatedAt = '2026-07-30T09:00:00.000Z';
const fixtureCreatedAt = '2026-07-01T06:30:00.000Z';
const fixtureExpiresAt = '2026-07-30T09:05:00.000Z';
const fixtureAccessToken = 'saeq-test-access-token-1';

/// Synthetic contact fixture values (fake `Customer Contact` style data).
const fixtureCustomerName = 'Customer Contact';
const fixtureCustomerPhone = '+966500000001';

/// Canonical Backend ErrorEnvelope (contracts-v0.1.0) fixture.
Map<String, dynamic> errorEnvelopeJson(
  String code, {
  String message = 'scripted failure',
  bool retryable = false,
  Map<String, dynamic> details = const <String, dynamic>{},
}) => {
  'code': code,
  'message': message,
  'requestId': fixtureRequestId,
  'retryable': retryable,
  'details': details,
};

Map<String, dynamic> otpChallengeJson() => {
  'challengeId': fixtureChallengeId,
  'expiresAt': fixtureExpiresAt,
  'resendAvailableAt': '2026-07-30T09:00:30.000Z',
};

Map<String, dynamic> authDriverJson() => {
  'driverId': fixtureDriverId,
  'displayName': 'Test Driver',
  'phoneMasked': '+9665****5678',
  'locale': 'ar-SA',
  'status': 'active',
};

Map<String, dynamic> tokenResponseJson({
  String accessToken = fixtureAccessToken,
  String refreshToken = 'saeq-test-refresh-token-1',
}) => {
  'accessToken': accessToken,
  'accessTokenExpiresAt': '2026-07-30T10:00:00.000Z',
  'refreshToken': refreshToken,
  'refreshTokenExpiresAt': '2026-08-29T09:00:00.000Z',
  'tokenType': 'Bearer',
  'driver': authDriverJson(),
};

Map<String, dynamic> driverProfileJson({String status = 'active'}) => {
  'driverId': fixtureDriverId,
  'displayName': 'Test Driver',
  'phoneMasked': '+9665****5678',
  'locale': 'ar-SA',
  'status': status,
  'createdAt': fixtureCreatedAt,
  'updatedAt': fixtureUpdatedAt,
  'vehicleType': 'sedan',
};

Map<String, dynamic> driverComplianceJson() => {
  'overallStatus': 'compliant',
  'requirements': [
    {'code': 'nationalId', 'status': 'approved'},
    {'code': 'vehicleRegistration', 'status': 'approved', 'message': 'ok'},
  ],
  'blockingReasons': <String>[],
  'lastEvaluatedAt': fixtureUpdatedAt,
};

Map<String, dynamic> driverAvailabilityJson({String status = 'available'}) => {
  'status': status,
  'updatedAt': fixtureUpdatedAt,
  'reason': null,
};

Map<String, dynamic> offerSummaryJson({
  String offerId = fixtureOfferId,
  String status = 'offered',
  int aggregateVersion = 3,
}) => {
  'offerId': offerId,
  'status': status,
  'estimatedDistanceMeters': 4200,
  'estimatedDurationSeconds': 900,
  'compensation': {'amount': 18.5, 'currency': 'SAR'},
  'pickup': {
    'label': 'Merchant A',
    'location': {'latitude': 24.7136, 'longitude': 46.6753},
  },
  'dropoff': {
    'label': 'District B',
    'location': {'latitude': 24.7743, 'longitude': 46.7386},
  },
  'expiresAt': fixtureExpiresAt,
  'aggregateVersion': aggregateVersion,
};

/// Paginated offers page (contracts-v0.1.0 `items` + cursor pagination).
Map<String, dynamic> offersPageJson({List<Map<String, dynamic>>? items}) => {
  'items': items ?? [offerSummaryJson()],
  'nextCursor': null,
};

Map<String, dynamic> offerActionResponseJson({
  String state = 'accepted',
  int aggregateVersion = 4,
}) => {
  'offerId': fixtureOfferId,
  'deliveryId': fixtureDeliveryId,
  'state': state,
  'aggregateVersion': aggregateVersion,
};

Map<String, dynamic> deliveryMutationJson({
  String state = 'pickupConfirmedManually',
  int aggregateVersion = 1,
}) => {
  'deliveryId': fixtureDeliveryId,
  'state': state,
  'aggregateVersion': aggregateVersion,
  'updatedAt': fixtureUpdatedAt,
};

/// Full Delivery resource shape used by GET active / GET by id.
Map<String, dynamic> deliveryResourceJson({
  String state = 'pickupAwaitingManualConfirmation',
  int aggregateVersion = 0,
}) => {
  'deliveryId': fixtureDeliveryId,
  'state': state,
  'aggregateVersion': aggregateVersion,
  'updatedAt': fixtureUpdatedAt,
  'pickup': {'label': 'Merchant A'},
  'dropoff': {'label': 'District B'},
};

Map<String, dynamic> batchStopJson({
  int sequence = 1,
  String deliveryId = fixtureDeliveryId,
  String stopType = 'dropoff',
  String label = 'Stop 1',
}) => {
  'sequence': sequence,
  'deliveryId': deliveryId,
  'stopType': stopType,
  'label': label,
};

Map<String, dynamic> batchSummaryJson({
  List<Map<String, dynamic>>? stops,
  int currentStopSequence = 1,
  int aggregateVersion = 2,
}) => {
  'batchId': fixtureBatchId,
  'currentStopSequence': currentStopSequence,
  'aggregateVersion': aggregateVersion,
  'stops':
      stops ??
      [
        batchStopJson(),
        batchStopJson(sequence: 2, deliveryId: fixtureOfferId, label: 'Stop 2'),
      ],
};

Map<String, dynamic> customerContactJson() => {
  'deliveryId': fixtureDeliveryId,
  'name': fixtureCustomerName,
  'phoneNumber': fixtureCustomerPhone,
  'availableUntil': fixtureExpiresAt,
};

// ---------------------------------------------------------------------------
// Endpoint catalog (23/23 contracts-v0.1.0 driver endpoints).
// ---------------------------------------------------------------------------

/// Replaces fixture ids with `{placeholder}` templates for coverage keys.
String templatePath(String path) => path
    .replaceAll(fixtureOfferId, '{offerId}')
    .replaceAll(fixtureDeliveryId, '{deliveryId}')
    .replaceAll(fixtureBatchId, '{batchId}');

final class ContractEndpoint {
  const ContractEndpoint(this.method, this.path, this.coveredBy);

  final String method;

  /// Templated path (`{offerId}` style placeholders for path parameters).
  final String path;

  /// Test file (under `contract_wire/`) exercising this endpoint on the wire.
  final String coveredBy;

  String get key => '$method $path';
}

/// All driver-facing endpoints of contracts-v0.1.0 — exactly 23.
final contractWireEndpointCatalog = List<ContractEndpoint>.unmodifiable([
  // Auth (4)
  ContractEndpoint('POST', DriverApiPaths.otpRequest, 'auth'),
  ContractEndpoint('POST', DriverApiPaths.otpVerify, 'auth'),
  ContractEndpoint('POST', DriverApiPaths.tokenRefresh, 'auth'),
  ContractEndpoint('POST', DriverApiPaths.logout, 'auth'),
  // Driver (3)
  ContractEndpoint('GET', DriverApiPaths.driverMe, 'driver_profile'),
  ContractEndpoint('PATCH', DriverApiPaths.driverMe, 'driver_profile'),
  ContractEndpoint('GET', DriverApiPaths.driverCompliance, 'driver_profile'),
  // Availability (2)
  ContractEndpoint('GET', DriverApiPaths.driverAvailability, 'availability'),
  ContractEndpoint('PUT', DriverApiPaths.driverAvailability, 'availability'),
  // Offers (4)
  ContractEndpoint('GET', DriverApiPaths.offers, 'offers'),
  ContractEndpoint(
    'GET',
    templatePath(DriverApiPaths.offerById(fixtureOfferId)),
    'offers',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.offerAccept(fixtureOfferId)),
    'offers',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.offerReject(fixtureOfferId)),
    'offers',
  ),
  // Deliveries (7)
  ContractEndpoint('GET', DriverApiPaths.deliveriesActive, 'deliveries'),
  ContractEndpoint(
    'GET',
    templatePath(DriverApiPaths.deliveryById(fixtureDeliveryId)),
    'deliveries',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.deliveryPickupConfirmation(fixtureDeliveryId)),
    'deliveries',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.deliveryArrival(fixtureDeliveryId)),
    'deliveries',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.deliveryConfirmation(fixtureDeliveryId)),
    'deliveries',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.deliveryCancel(fixtureDeliveryId)),
    'deliveries',
  ),
  ContractEndpoint(
    'POST',
    templatePath(DriverApiPaths.deliveryIssues(fixtureDeliveryId)),
    'deliveries',
  ),
  // Batches (2)
  ContractEndpoint('GET', DriverApiPaths.batchesActive, 'batches_and_contact'),
  ContractEndpoint(
    'GET',
    templatePath(DriverApiPaths.batchById(fixtureBatchId)),
    'batches_and_contact',
  ),
  // Customer contact (1)
  ContractEndpoint(
    'GET',
    templatePath(DriverApiPaths.deliveryCustomerContact(fixtureDeliveryId)),
    'batches_and_contact',
  ),
]);

/// Catalog slice covered by one wire test file (see [ContractEndpoint.key]).
Set<String> catalogSlice(String coveredBy) => contractWireEndpointCatalog
    .where((e) => e.coveredBy == coveredBy)
    .map((e) => e.key)
    .toSet();

// ---------------------------------------------------------------------------
// Recording adapter + harness.
// ---------------------------------------------------------------------------

final class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.queryParameters,
    this.body,
  });

  final String method;
  final String path;

  /// Header map with lower-cased keys.
  final Map<String, Object?> headers;
  final Map<String, dynamic> queryParameters;
  final Object? body;

  String? header(String name) => headers[name.toLowerCase()]?.toString();

  Map<String, dynamic> get bodyAsMap => Map<String, dynamic>.from(body as Map);
}

sealed class _ScriptedOutcome {
  const _ScriptedOutcome();
}

final class _ScriptedResponse extends _ScriptedOutcome {
  const _ScriptedResponse(this.statusCode, this.body);

  final int statusCode;
  final Object? body;
}

final class _ScriptedTransportError extends _ScriptedOutcome {
  const _ScriptedTransportError(this.type);

  final DioExceptionType type;
}

class _RecordingScriptedAdapter implements HttpClientAdapter {
  _RecordingScriptedAdapter(this._harness);

  final ContractWireHarness _harness;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final recorded = RecordedRequest(
      method: options.method,
      path: options.path,
      headers: options.headers.map(
        (key, value) => MapEntry(key.toLowerCase(), value),
      ),
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      body: options.data,
    );
    _harness.requests.add(recorded);
    ContractWireHarness.coverage.add(
      '${options.method} ${templatePath(options.path)}',
    );

    if (_harness._script.isEmpty) {
      throw StateError(
        'No scripted response for ${options.method} ${options.path}',
      );
    }
    final outcome = _harness._script.removeAt(0);
    switch (outcome) {
      case _ScriptedTransportError(:final type):
        throw DioException(
          requestOptions: options,
          type: type,
          error: 'scripted transport failure',
        );
      case _ScriptedResponse(:final statusCode, :final body):
        return ResponseBody.fromString(
          body == null ? '' : jsonEncode(body),
          statusCode,
          headers: {
            if (body != null)
              Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    }
  }
}

class SilentLogger implements LoggerService {
  @override
  LogLevel level = LogLevel.debug;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}
}

final class ContractWireHarness {
  ContractWireHarness({
    String? accessToken = fixtureAccessToken,
    TokenRefreshCallback? onUnauthorizedRefresh,
  }) : tokenCache = AccessTokenMemoryCache()..setAccessToken(accessToken) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.saeq.test',
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.httpClientAdapter = _RecordingScriptedAdapter(this);
    api = SaeqApiClient(
      baseUrl: 'https://api.saeq.test',
      accessTokenCache: tokenCache,
      logger: SilentLogger(),
      dio: dio,
      onUnauthorizedRefresh: onUnauthorizedRefresh,
    );
  }

  /// Wire-level endpoint coverage accumulated per test isolate (file).
  static final Set<String> coverage = <String>{};

  final AccessTokenMemoryCache tokenCache;
  late final Dio dio;
  late final SaeqApiClient api;

  final List<RecordedRequest> requests = [];
  final List<_ScriptedOutcome> _script = [];

  RecordedRequest get single {
    if (requests.length != 1) {
      throw StateError('Expected exactly one request, got ${requests.length}');
    }
    return requests.single;
  }

  RecordedRequest get last => requests.last;

  void enqueue(int statusCode, [Object? body]) =>
      _script.add(_ScriptedResponse(statusCode, body));

  void enqueueTimeout() => _script.add(
    const _ScriptedTransportError(DioExceptionType.connectionTimeout),
  );

  void enqueueNetworkFailure() => _script.add(
    const _ScriptedTransportError(DioExceptionType.connectionError),
  );
}

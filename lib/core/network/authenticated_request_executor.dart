import 'package:dio/dio.dart';

import 'saeq_api_client.dart';

/// Executes authenticated HTTP calls through [SaeqApiClient].
///
/// Controllers and use cases must not call Dio / parse JSON via this type —
/// feature remote data sources sit between repositories and this executor.
final class AuthenticatedRequestExecutor {
  AuthenticatedRequestExecutor({required SaeqApiClient apiClient})
    : _api = apiClient;

  final SaeqApiClient _api;

  SaeqApiClient get apiClient => _api;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _api.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
  }) => _api.post<T>(path, data: data, idempotencyKey: idempotencyKey);

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
  }) => _api.put<T>(path, data: data, idempotencyKey: idempotencyKey);

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
  }) => _api.patch<T>(path, data: data, idempotencyKey: idempotencyKey);
}

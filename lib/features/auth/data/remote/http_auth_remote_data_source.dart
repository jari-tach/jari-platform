import '../../../../core/backend_configuration/driver_api_paths.dart';
import '../../../../core/network/saeq_api_client.dart';
import '../models/otp_challenge_wire.dart';
import '../models/token_response_wire.dart';
import 'auth_remote_data_source.dart';

final class HttpAuthRemoteDataSource implements AuthRemoteDataSource {
  HttpAuthRemoteDataSource({required SaeqApiClient apiClient})
    : _api = apiClient;

  final SaeqApiClient _api;

  @override
  Future<OtpChallengeWire> requestOtp({
    required String phoneNumber,
    required String locale,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.otpRequest,
      data: {'phoneNumber': phoneNumber, 'locale': locale},
      authenticated: false,
    );
    return OtpChallengeWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<TokenResponseWire> verifyOtp({
    required String challengeId,
    required String otpCode,
    required String idempotencyKey,
    Map<String, dynamic>? device,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.otpVerify,
      data: {
        'challengeId': challengeId,
        'otpCode': otpCode,
        if (device != null) 'device': device,
      },
      idempotencyKey: idempotencyKey,
      authenticated: false,
    );
    return TokenResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<TokenResponseWire> refreshToken({
    required String refreshToken,
    required String idempotencyKey,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.tokenRefresh,
      data: {'refreshToken': refreshToken},
      idempotencyKey: idempotencyKey,
      authenticated: false,
    );
    return TokenResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> logout({
    required String refreshToken,
    required String idempotencyKey,
  }) async {
    await _api.post<void>(
      DriverApiPaths.logout,
      data: {'refreshToken': refreshToken},
      idempotencyKey: idempotencyKey,
      authenticated: true,
    );
  }
}

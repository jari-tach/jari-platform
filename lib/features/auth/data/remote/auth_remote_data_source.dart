import '../models/otp_challenge_wire.dart';
import '../models/token_response_wire.dart';

/// Remote auth transport port (STEP 5C-1).
abstract interface class AuthRemoteDataSource {
  Future<OtpChallengeWire> requestOtp({
    required String phoneNumber,
    required String locale,
  });

  Future<TokenResponseWire> verifyOtp({
    required String challengeId,
    required String otpCode,
    required String idempotencyKey,
    Map<String, dynamic>? device,
  });

  Future<TokenResponseWire> refreshToken({
    required String refreshToken,
    required String idempotencyKey,
  });

  Future<void> logout({
    required String refreshToken,
    required String idempotencyKey,
  });
}

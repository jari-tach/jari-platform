import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/repositories/authentication_repository.dart';
import 'auth_controller_state.dart';

/// Drives the authentication lifecycle for the whole app.
///
/// Restoration is kicked off exactly once, the first time this controller
/// is read (see [build]). A missing/failed [AuthenticationRepository] (see
/// PHASE 2.1's non-critical bootstrap failure policy) degrades to
/// `unauthenticated` instead of crashing — the user simply sees the Login
/// screen and any sign-in attempt fails cleanly.
class AuthController extends Notifier<AuthControllerState> {
  AuthController({
    AuthenticationRepository? Function(Ref ref)? repositoryReader,
  }) : _repositoryReader = repositoryReader ?? _defaultRepositoryReader;

  final AuthenticationRepository? Function(Ref ref) _repositoryReader;

  static AuthenticationRepository? _defaultRepositoryReader(Ref ref) => null;

  bool _isBusy = false;
  bool _restoreStarted = false;
  Future<void>? _refreshInFlight;

  AuthenticationRepository? get _repository => _repositoryReader(ref);

  @override
  AuthControllerState build() {
    if (!_restoreStarted) {
      _restoreStarted = true;
      Future.microtask(_restoreSession);
    }
    return const AuthControllerState.initial();
  }

  Future<void> _restoreSession() async {
    state = const AuthControllerState.restoring();

    final repository = _repository;
    if (repository == null) {
      state = const AuthControllerState.unauthenticated();
      return;
    }

    try {
      final session = await repository.restoreSession();
      state = session != null
          ? AuthControllerState.authenticated(session)
          : const AuthControllerState.unauthenticated();
    } catch (_) {
      state = const AuthControllerState.unauthenticated();
    }
  }

  Future<void> signIn(String phoneNumber) async {
    if (_isBusy) return;

    final repository = _repository;
    if (repository == null) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
      return;
    }

    _isBusy = true;
    state = const AuthControllerState.authenticating();
    try {
      final session = await repository.signIn(phoneNumber);
      state = AuthControllerState.authenticated(session);
    } on AuthError catch (error) {
      state = _stateForAuthError(error);
    } catch (_) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
    } finally {
      _isBusy = false;
    }
  }

  Future<void> requestOtp(String phoneNumber) async {
    if (_isBusy) return;

    final repository = _repository;
    if (repository == null) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
      return;
    }

    _isBusy = true;
    state = const AuthControllerState.requestingOtp();
    try {
      await repository.requestOtp(phoneNumber);
      state = AuthControllerState.otpRequested(
        pendingPhone: phoneNumber,
        resendAvailableAt:
            repository.otpResendAvailableAt ??
            DateTime.now().add(const Duration(seconds: 30)),
      );
    } on AuthError catch (error) {
      state = _stateForAuthError(error);
    } catch (_) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
    } finally {
      _isBusy = false;
    }
  }

  Future<void> verifyOtp(String otpCode) async {
    if (_isBusy) return;

    final pendingPhone = state.pendingPhone;
    if (pendingPhone == null) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
      return;
    }

    final repository = _repository;
    if (repository == null) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
      return;
    }

    final resendAvailableAt =
        state.resendAvailableAt ??
        repository.otpResendAvailableAt ??
        DateTime.now();

    _isBusy = true;
    state = AuthControllerState.verifyingOtp(
      pendingPhone: pendingPhone,
      resendAvailableAt: resendAvailableAt,
    );
    try {
      final session = await repository.verifyOtp(
        phoneNumber: pendingPhone,
        otpCode: otpCode.trim(),
      );
      state = AuthControllerState.authenticated(session);
    } on AuthError catch (error) {
      if (error is SessionExpiredError) {
        state = AuthControllerState.expired(error);
      } else {
        state = AuthControllerState.otpRequested(
          pendingPhone: pendingPhone,
          resendAvailableAt: resendAvailableAt,
          error: error,
        );
      }
    } catch (_) {
      state = AuthControllerState.otpRequested(
        pendingPhone: pendingPhone,
        resendAvailableAt: resendAvailableAt,
        error: const UnexpectedAuthError(),
      );
    } finally {
      _isBusy = false;
    }
  }

  Future<void> resendOtp() async {
    final pendingPhone = state.pendingPhone;
    if (pendingPhone == null || _isBusy) return;

    final repository = _repository;
    if (repository == null) {
      state = AuthControllerState.otpRequested(
        pendingPhone: pendingPhone,
        resendAvailableAt: state.resendAvailableAt ?? DateTime.now(),
        error: const UnexpectedAuthError(),
      );
      return;
    }

    final resendAvailableAt = state.resendAvailableAt;
    if (resendAvailableAt != null &&
        DateTime.now().isBefore(resendAvailableAt)) {
      state = AuthControllerState.otpRequested(
        pendingPhone: pendingPhone,
        resendAvailableAt: resendAvailableAt,
        error: const OtpRateLimitedError(),
      );
      return;
    }

    _isBusy = true;
    final previousResendAt = resendAvailableAt ?? DateTime.now();
    state = const AuthControllerState.requestingOtp();
    try {
      await repository.requestOtp(pendingPhone);
      state = AuthControllerState.otpRequested(
        pendingPhone: pendingPhone,
        resendAvailableAt:
            repository.otpResendAvailableAt ??
            DateTime.now().add(const Duration(seconds: 30)),
      );
    } on AuthError catch (error) {
      state = AuthControllerState.otpRequested(
        pendingPhone: pendingPhone,
        resendAvailableAt: previousResendAt,
        error: error,
      );
    } catch (_) {
      state = AuthControllerState.otpRequested(
        pendingPhone: pendingPhone,
        resendAvailableAt: previousResendAt,
        error: const UnexpectedAuthError(),
      );
    } finally {
      _isBusy = false;
    }
  }

  void clearOtpFlow() {
    _repository?.clearOtpChallenge();
    if (state.status == AuthControllerStatus.failure ||
        state.status == AuthControllerStatus.otpRequested ||
        state.status == AuthControllerStatus.requestingOtp ||
        state.status == AuthControllerStatus.verifyingOtp) {
      state = const AuthControllerState.unauthenticated();
    }
  }

  Future<void> signOut() async {
    if (state.status == AuthControllerStatus.signingOut) return;
    if (state.status == AuthControllerStatus.unauthenticated) return;

    final previousSession = state.session;
    state = const AuthControllerState.signingOut();
    final repository = _repository;
    if (repository == null) {
      _clearCustomerContactMemory();
      state = const AuthControllerState.unauthenticated();
      return;
    }

    try {
      await repository.signOut();
      repository.clearOtpChallenge();
      _clearCustomerContactMemory();
      state = const AuthControllerState.unauthenticated();
    } on SecureStorageFailureError catch (error) {
      if (previousSession != null) {
        state = AuthControllerState.failure(error, session: previousSession);
      } else {
        state = AuthControllerState.failure(error);
      }
    } catch (_) {
      if (previousSession != null) {
        state = AuthControllerState.authenticated(previousSession);
      } else {
        _clearCustomerContactMemory();
        state = const AuthControllerState.unauthenticated();
      }
    }
  }

  /// Clears memory-only customer contact on logout / session expiration.
  void _clearCustomerContactMemory() {
    if (!AppServiceRegistry.isInitialized) return;
    AppServiceRegistry.deliveryLifecycleRepository?.clearCustomerContact();
    AppServiceRegistry.customerContactMemoryCache?.clear();
    AppServiceRegistry.deliveryLifecycleRemote?.onLogoutOrSessionExpired();
  }

  Future<void> refreshSession() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    if (_isBusy) return;

    final repository = _repository;
    if (repository == null) return;
    if (state.status != AuthControllerStatus.authenticated) return;

    _refreshInFlight = _refreshSessionBody();
    try {
      await _refreshInFlight!;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _refreshSessionBody() async {
    final repository = _repository;
    if (repository == null) return;

    try {
      final session = await repository.refreshSession();
      if (session != null) {
        state = AuthControllerState.authenticated(session);
      } else {
        state = const AuthControllerState.unauthenticated();
      }
    } catch (_) {
      state = const AuthControllerState.unauthenticated();
    }
  }

  void clearError() {
    if (state.status == AuthControllerStatus.failure) {
      final pendingPhone = state.pendingPhone;
      final resendAvailableAt = state.resendAvailableAt;
      if (pendingPhone != null && resendAvailableAt != null) {
        state = AuthControllerState.otpRequested(
          pendingPhone: pendingPhone,
          resendAvailableAt: resendAvailableAt,
        );
      } else {
        state = const AuthControllerState.unauthenticated();
      }
      return;
    }

    if (state.status == AuthControllerStatus.otpRequested &&
        state.error != null) {
      state = AuthControllerState.otpRequested(
        pendingPhone: state.pendingPhone!,
        resendAvailableAt: state.resendAvailableAt!,
      );
    }
  }

  /// Test-only: ends the OTP resend cooldown without waiting wall-clock time.
  @visibleForTesting
  void debugForceResendAvailable() {
    final pendingPhone = state.pendingPhone;
    if (pendingPhone == null) return;
    state = AuthControllerState.otpRequested(
      pendingPhone: pendingPhone,
      resendAvailableAt: DateTime.now().subtract(const Duration(seconds: 1)),
      error: state.error,
    );
  }

  AuthControllerState _stateForAuthError(AuthError error) {
    if (error is SessionExpiredError) {
      _clearCustomerContactMemory();
      return AuthControllerState.expired(error);
    }
    return AuthControllerState.failure(error);
  }
}

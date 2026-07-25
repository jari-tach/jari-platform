import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  AuthenticationRepository? get _repository => _repositoryReader(ref);

  @override
  AuthControllerState build() {
    // Restoration must run exactly once per controller lifetime (Phase 7):
    // guard against build() being re-invoked by an unrelated dependency
    // change.
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
      // AuthenticationRepository failed to initialize (see
      // AppServiceRegistry). Fail safe: treat as unauthenticated, never
      // crash, never get stuck in restoring.
      state = const AuthControllerState.unauthenticated();
      return;
    }

    try {
      final session = await repository.restoreSession();
      state = session != null
          ? AuthControllerState.authenticated(session)
          : const AuthControllerState.unauthenticated();
    } catch (_) {
      // AuthenticationRepository.restoreSession() is contractually not
      // supposed to throw for normal cases; this is defense-in-depth so a
      // misbehaving implementation still can't block app startup.
      state = const AuthControllerState.unauthenticated();
    }
  }

  Future<void> signIn(String phoneNumber) async {
    if (_isBusy) return; // Prevent duplicate/concurrent sign-in requests.

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
      state = AuthControllerState.failure(error);
    } catch (_) {
      state = const AuthControllerState.failure(UnexpectedAuthError());
    } finally {
      _isBusy = false;
    }
  }

  Future<void> signOut() async {
    // Idempotent: a repeated sign-out while one is already in flight (or
    // once already signed out) must never throw or double-fire storage
    // clears.
    if (state.status == AuthControllerStatus.signingOut) return;
    if (state.status == AuthControllerStatus.unauthenticated) return;

    state = const AuthControllerState.signingOut();
    final repository = _repository;
    if (repository != null) {
      try {
        await repository.signOut();
      } catch (_) {
        // signOut() must never crash the app; fall through to
        // unauthenticated regardless of the underlying failure.
      }
    }
    state = const AuthControllerState.unauthenticated();
  }

  /// Clears a [AuthControllerStatus.failure] state so the Login screen can
  /// show a clean form again on retry, without re-running restoration.
  void clearError() {
    if (state.status == AuthControllerStatus.failure) {
      state = const AuthControllerState.unauthenticated();
    }
  }
}

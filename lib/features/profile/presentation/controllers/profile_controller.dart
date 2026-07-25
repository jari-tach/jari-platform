import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile_error.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import 'profile_controller_state.dart';

/// Loads and refreshes the current driver profile (PHASE 2.3).
class ProfileController extends Notifier<ProfileControllerState> {
  ProfileController({
    DriverProfileRepository? Function(Ref ref)? repositoryReader,
  }) : _repositoryReader = repositoryReader ?? _defaultReader;

  final DriverProfileRepository? Function(Ref ref) _repositoryReader;

  static DriverProfileRepository? _defaultReader(Ref ref) => null;

  bool _loadStarted = false;

  DriverProfileRepository? get _repository => _repositoryReader(ref);

  @override
  ProfileControllerState build() {
    if (!_loadStarted) {
      _loadStarted = true;
      Future.microtask(load);
    }
    return const ProfileControllerState.initial();
  }

  Future<void> load() async {
    state = const ProfileControllerState.loading();

    final repository = _repository;
    if (repository == null) {
      state = const ProfileControllerState.error(ProfileUnexpectedError());
      return;
    }

    try {
      final profile = await repository.getCurrentProfile();
      state = ProfileControllerState.success(profile);
    } on ProfileUnauthenticatedError catch (error) {
      state = ProfileControllerState.error(error);
    } on ProfileSessionExpiredError catch (error) {
      state = ProfileControllerState.sessionExpired(error);
    } on ProfileNotFoundError {
      state = const ProfileControllerState.empty();
    } on ProfileError catch (error) {
      state = ProfileControllerState.error(error);
    } catch (_) {
      state = const ProfileControllerState.error(ProfileUnexpectedError());
    }
  }

  Future<void> retry() => load();
}

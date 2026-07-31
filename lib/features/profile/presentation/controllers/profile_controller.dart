import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/remote_driver_profile_repository.dart';
import '../../domain/entities/profile_error.dart';
import '../../domain/repositories/driver_profile_repository.dart';
import 'profile_controller_state.dart';

/// Loads and refreshes the current driver profile (PHASE 2.3 / STEP 5D-1).
class ProfileController extends Notifier<ProfileControllerState> {
  ProfileController({
    DriverProfileRepository? Function(Ref ref)? repositoryReader,
  }) : _repositoryReader = repositoryReader ?? _defaultReader;

  final DriverProfileRepository? Function(Ref ref) _repositoryReader;

  static DriverProfileRepository? _defaultReader(Ref ref) => null;

  bool _loadStarted = false;
  bool _updateInProgress = false;

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
      DriverComplianceSnapshot? compliance;
      if (repository is RemoteDriverProfileRepository) {
        try {
          compliance = await repository.getCompliance();
        } catch (_) {
          // Compliance is non-blocking for profile presentation.
          compliance = repository.lastCompliance;
        }
      }
      state = ProfileControllerState.success(profile, compliance: compliance);
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

  /// Updates client-editable profile fields. Preserves the prior profile on
  /// failure and ignores duplicate concurrent calls.
  Future<bool> updateProfile(DriverProfileUpdate update) async {
    if (_updateInProgress || !update.hasChanges) {
      return !update.hasChanges;
    }

    final priorProfile = state.profile;
    if (priorProfile == null) return false;

    final repository = _repository;
    if (repository == null) return false;

    _updateInProgress = true;
    state = state.copyWith(isUpdating: true);

    try {
      final updated = await repository.updateCurrentProfile(update);
      state = ProfileControllerState.success(
        updated,
        compliance: state.compliance,
      );
      return true;
    } on ProfileError {
      state = ProfileControllerState.success(
        priorProfile,
        compliance: state.compliance,
      );
      return false;
    } catch (_) {
      state = ProfileControllerState.success(
        priorProfile,
        compliance: state.compliance,
      );
      return false;
    } finally {
      _updateInProgress = false;
      if (state.isUpdating) {
        state = state.copyWith(isUpdating: false);
      }
    }
  }
}

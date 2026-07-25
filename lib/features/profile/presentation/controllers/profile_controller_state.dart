import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/profile_error.dart';

enum ProfileViewStatus {
  initial,
  loading,
  success,
  empty,
  error,
  sessionExpired,
}

class ProfileControllerState {
  const ProfileControllerState({
    required this.status,
    this.profile,
    this.error,
  });

  const ProfileControllerState.initial()
    : this(status: ProfileViewStatus.initial);

  const ProfileControllerState.loading()
    : this(status: ProfileViewStatus.loading);

  const ProfileControllerState.success(DriverProfile profile)
    : this(status: ProfileViewStatus.success, profile: profile);

  const ProfileControllerState.empty() : this(status: ProfileViewStatus.empty);

  const ProfileControllerState.error(ProfileError error)
    : this(status: ProfileViewStatus.error, error: error);

  const ProfileControllerState.sessionExpired([ProfileError? error])
    : this(
        status: ProfileViewStatus.sessionExpired,
        error: error ?? const ProfileSessionExpiredError(),
      );

  final ProfileViewStatus status;
  final DriverProfile? profile;
  final ProfileError? error;

  bool get canRetry =>
      status == ProfileViewStatus.error ||
      status == ProfileViewStatus.sessionExpired ||
      status == ProfileViewStatus.empty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileControllerState &&
          status == other.status &&
          profile == other.profile &&
          error == other.error;

  @override
  int get hashCode => Object.hash(status, profile, error);
}

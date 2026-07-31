import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/profile_error.dart';
import '../../data/repositories/remote_driver_profile_repository.dart';

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
    this.compliance,
    this.error,
    this.isUpdating = false,
  });

  const ProfileControllerState.initial()
    : this(status: ProfileViewStatus.initial);

  const ProfileControllerState.loading()
    : this(status: ProfileViewStatus.loading);

  const ProfileControllerState.success(
    DriverProfile profile, {
    DriverComplianceSnapshot? compliance,
  }) : this(
         status: ProfileViewStatus.success,
         profile: profile,
         compliance: compliance,
       );

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
  final DriverComplianceSnapshot? compliance;
  final ProfileError? error;
  final bool isUpdating;

  ProfileControllerState copyWith({
    ProfileViewStatus? status,
    DriverProfile? profile,
    DriverComplianceSnapshot? compliance,
    bool clearCompliance = false,
    ProfileError? error,
    bool? isUpdating,
  }) {
    return ProfileControllerState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      compliance: clearCompliance ? null : (compliance ?? this.compliance),
      error: error ?? this.error,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

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
          compliance == other.compliance &&
          error == other.error &&
          isUpdating == other.isUpdating;

  @override
  int get hashCode =>
      Object.hash(status, profile, compliance, error, isUpdating);
}

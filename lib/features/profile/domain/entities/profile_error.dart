/// Typed profile errors (PHASE 2.3). Safe for logs — never include tokens.
sealed class ProfileError implements Exception {
  const ProfileError(this.message);

  final String message;

  @override
  String toString() => '[$runtimeType] $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class ProfileUnauthenticatedError extends ProfileError {
  const ProfileUnauthenticatedError([
    super.message = 'No authenticated session available.',
  ]);
}

final class ProfileSessionExpiredError extends ProfileError {
  const ProfileSessionExpiredError([
    super.message = 'Session expired while loading profile.',
  ]);
}

final class ProfileNotFoundError extends ProfileError {
  const ProfileNotFoundError([super.message = 'Driver profile was not found.']);
}

final class ProfileForbiddenError extends ProfileError {
  const ProfileForbiddenError([
    super.message = 'Access to this profile is not allowed.',
  ]);
}

final class ProfileInvalidDataError extends ProfileError {
  const ProfileInvalidDataError([
    super.message = 'Profile data is incomplete or invalid.',
  ]);
}

final class ProfileSovereignFieldMutationError extends ProfileError {
  const ProfileSovereignFieldMutationError([
    super.message =
        'Cannot modify sovereign identity fields '
        '(driverId/businessId/branchId/phoneNumber/'
        'employmentStatus/accountStatus/createdAt).',
  ]);
}

final class ProfileUnexpectedError extends ProfileError {
  const ProfileUnexpectedError([super.message = 'Unexpected profile error.']);
}

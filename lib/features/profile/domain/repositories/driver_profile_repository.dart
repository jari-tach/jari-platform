import '../entities/driver_profile.dart';
import '../entities/driver_profile_update.dart';

export '../entities/driver_profile_update.dart';

/// Contract for loading/updating the current driver's profile.
///
/// Implementations may use Fake/local cache in non-production; Backend will
/// become the source of truth for business/branch binding.
abstract interface class DriverProfileRepository {
  /// Loads the profile for the currently authenticated driver.
  ///
  /// Throws [ProfileUnauthenticatedError] / [ProfileSessionExpiredError] /
  /// [ProfileNotFoundError] / etc. Never returns a profile for another driver.
  Future<DriverProfile> getCurrentProfile();

  /// Applies a non-sovereign update for the current driver only.
  Future<DriverProfile> updateCurrentProfile(DriverProfileUpdate update);
}

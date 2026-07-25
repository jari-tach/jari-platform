/// Account verification / eligibility status for a driver profile.
///
/// Backend is the future source of truth. Fake data may return [pending].
enum AccountStatus { pending, verified, rejected, suspended }

/// Employment relationship status for a driver under a business/branch.
enum EmploymentStatus { active, inactive, onLeave, terminated }

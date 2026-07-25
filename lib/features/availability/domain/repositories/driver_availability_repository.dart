import '../entities/authoritative_availability_update.dart';
import '../entities/availability_change_request.dart';
import '../entities/availability_reconciliation_request.dart';
import '../entities/availability_result.dart';
import '../entities/driver_availability.dart';
import '../entities/logout_availability_request.dart';

/// Domain contract for driver operational availability (PHASE 2.4).
///
/// Session-scoped like profile: implementations resolve the current driver.
/// Request objects still carry [driverId] for explicit identity checks.
/// Local state is never implied to be Backend authority (ADR-016).
abstract interface class DriverAvailabilityRepository {
  /// Snapshot of effective domain availability.
  ///
  /// Authority: local effective view only — not Backend confirmation.
  /// Offline: returns last known effective state or typed failure.
  Future<AvailabilityResult<DriverAvailability>> getCurrentAvailability();

  /// Stream of effective domain availability changes.
  ///
  /// Authority: same as get — effective/local, not confirmed by emission alone.
  /// Side effects: none beyond observation. Errors surface on the stream.
  Stream<DriverAvailability> watchAvailability();

  /// Persist/apply a policy-approved change request (not authoritative publish).
  ///
  /// Authority: local intent / system actor as declared on [request].
  /// Offline: may accept unavailable intent with pendingSync; must not confirm
  /// available without connectivity (enforced by use case before call).
  Future<AvailabilityResult<DriverAvailability>> requestAvailabilityChange(
    AvailabilityChangeRequest request,
  );

  /// Restore previously persisted local snapshot.
  ///
  /// Authority: restored local state only — never auto-publishes available.
  /// Offline: allowed; restored available remains unconfirmed (ADR-019).
  Future<AvailabilityResult<DriverAvailability>> restoreLocalAvailability();

  /// Reconcile local intent with authoritative truth when available.
  ///
  /// Authority: Backend/system over local when conflict (ADR-016).
  /// Contract only in Increment 2 — no retry schedule or queue engine.
  Future<AvailabilityResult<DriverAvailability>> reconcileAvailability(
    AvailabilityReconciliationRequest request,
  );

  /// Invalidate local operational availability on logout (BR-AVAIL-016).
  ///
  /// Authority: local clear only — does not claim server confirmation.
  /// Does not modify auth session. Busy with assignment must not be silently
  /// erased by callers (use case enforces deterministic conflict).
  Future<AvailabilityResult<void>> clearAvailabilityOnLogout(
    LogoutAvailabilityRequest request,
  );

  /// Apply Backend/system authoritative snapshot.
  ///
  /// Authority: server/system. Rejects local-user sources at request VO /
  /// use-case boundary. May yield sync/stale typed failures.
  Future<AvailabilityResult<DriverAvailability>> applyAuthoritativeAvailability(
    AuthoritativeAvailabilityUpdate update,
  );
}

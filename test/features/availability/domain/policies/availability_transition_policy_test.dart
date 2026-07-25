import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/policies/availability_transition_decision.dart';
import 'package:saeq_driver/features/availability/domain/policies/availability_transition_policy.dart';

void main() {
  const policy = AvailabilityTransitionPolicy();

  AvailabilityTransitionDecision decide({
    required AvailabilityStatus current,
    required AvailabilityStatus requested,
    required AvailabilityActor actor,
    bool hasActiveAssignment = false,
    bool assignmentAllowsAvailable = false,
  }) => policy.evaluate(
    AvailabilityTransitionContext(
      current: current,
      requested: requested,
      actor: actor,
      hasActiveAssignment: hasActiveAssignment,
      assignmentAllowsAvailable: assignmentAllowsAvailable,
    ),
  );

  group('AvailabilityTransitionPolicy', () {
    test('unavailable → available structurally allowed for driver', () {
      final d = decide(
        current: AvailabilityStatus.unavailable,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.driver,
      );
      expect(d.allowed, isTrue);
      expect(d.idempotent, isFalse);
    });

    test('available → unavailable allowed for driver', () {
      final d = decide(
        current: AvailabilityStatus.available,
        requested: AvailabilityStatus.unavailable,
        actor: AvailabilityActor.driver,
      );
      expect(d.allowed, isTrue);
    });

    test('driver → busy denied with ManualBusyTransitionDenied', () {
      final d = decide(
        current: AvailabilityStatus.available,
        requested: AvailabilityStatus.busy,
        actor: AvailabilityActor.driver,
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<ManualBusyTransitionDenied>());
      expect(d.failure!.code, 'availability.manual_busy_denied');
    });

    test('system available → busy allowed', () {
      final d = decide(
        current: AvailabilityStatus.available,
        requested: AvailabilityStatus.busy,
        actor: AvailabilityActor.system,
      );
      expect(d.allowed, isTrue);
    });

    test('backend available → busy allowed', () {
      final d = decide(
        current: AvailabilityStatus.available,
        requested: AvailabilityStatus.busy,
        actor: AvailabilityActor.backend,
      );
      expect(d.allowed, isTrue);
    });

    test('busy → available denied for driver', () {
      final d = decide(
        current: AvailabilityStatus.busy,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.driver,
        assignmentAllowsAvailable: true,
      );
      expect(d.allowed, isFalse);
      expect(
        d.failure,
        anyOf(
          isA<InvalidAvailabilityTransition>(),
          isA<ActiveAssignmentConflict>(),
        ),
      );
    });

    test('busy → available allowed for system with valid context', () {
      final d = decide(
        current: AvailabilityStatus.busy,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.system,
        hasActiveAssignment: false,
        assignmentAllowsAvailable: true,
      );
      expect(d.allowed, isTrue);
    });

    test('busy → available allowed for backend with valid context', () {
      final d = decide(
        current: AvailabilityStatus.busy,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.backend,
        hasActiveAssignment: false,
        assignmentAllowsAvailable: true,
      );
      expect(d.allowed, isTrue);
    });

    test('busy → available denied for system without assignment release', () {
      final d = decide(
        current: AvailabilityStatus.busy,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.system,
        hasActiveAssignment: true,
        assignmentAllowsAvailable: false,
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<ActiveAssignmentConflict>());
    });

    test('offline → available denied', () {
      final d = decide(
        current: AvailabilityStatus.offline,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.driver,
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<AvailabilityOffline>());
    });

    test('identical transition is idempotent success', () {
      final d = decide(
        current: AvailabilityStatus.unavailable,
        requested: AvailabilityStatus.unavailable,
        actor: AvailabilityActor.driver,
      );
      expect(d.allowed, isTrue);
      expect(d.idempotent, isTrue);
    });

    test('undocumented transition default-denied', () {
      final d = decide(
        current: AvailabilityStatus.offline,
        requested: AvailabilityStatus.busy,
        actor: AvailabilityActor.system,
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<InvalidAvailabilityTransition>());
    });

    test('active assignment conflict prevents user → available', () {
      final d = decide(
        current: AvailabilityStatus.busy,
        requested: AvailabilityStatus.available,
        actor: AvailabilityActor.driver,
        hasActiveAssignment: true,
      );
      expect(d.allowed, isFalse);
      expect(d.failure, isA<ActiveAssignmentConflict>());
    });

    test(
      'active assignment conflict prevents user available → unavailable',
      () {
        final d = decide(
          current: AvailabilityStatus.available,
          requested: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          hasActiveAssignment: true,
        );
        expect(d.allowed, isFalse);
        expect(d.failure, isA<ActiveAssignmentConflict>());
      },
    );

    test('connectivity actor can force offline', () {
      final d = decide(
        current: AvailabilityStatus.available,
        requested: AvailabilityStatus.offline,
        actor: AvailabilityActor.connectivity,
      );
      expect(d.allowed, isTrue);
    });

    test('busy → unavailable allowed for system', () {
      final d = decide(
        current: AvailabilityStatus.busy,
        requested: AvailabilityStatus.unavailable,
        actor: AvailabilityActor.system,
      );
      expect(d.allowed, isTrue);
    });
  });
}

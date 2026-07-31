/// Shared STEP 5D-2 acceptance-test helpers.
///
/// Reuses the existing STEP 5D-1 fakes and the Local Command Ledger
/// ([FakeDeliveryCommandRepository]) — no second outbox is created.
library;

import 'package:saeq_driver/features/delivery/data/fake/fake_delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/batch_summary.dart';
import 'package:saeq_driver/features/delivery/domain/entities/customer_contact.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/repositories/delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/cancel_delivery_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/confirm_delivery_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/confirm_pickup_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_customer_contact.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/replay_pending_delivery_commands.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/report_automatic_arrival_remote.dart';

import '../../delivery/helpers/delivery_fixtures.dart';
import '../../delivery/helpers/fake_delivery_assignment_repository.dart';
import '../../delivery/helpers/fake_delivery_command_repository.dart';

/// One recorded Backend lifecycle mutation.
final class LifecycleMutation {
  const LifecycleMutation({
    required this.operation,
    required this.deliveryId,
    required this.aggregateVersion,
    required this.idempotencyKey,
    this.clientEventId,
  });

  final String operation;
  final String deliveryId;
  final int aggregateVersion;
  final String idempotencyKey;
  final String? clientEventId;
}

/// Records every Backend mutation (operation + Idempotency-Key) while
/// delegating behavior to the seeded [FakeDeliveryLifecycleRepository].
final class RecordingLifecycleRepository
    implements DeliveryLifecycleRepository {
  RecordingLifecycleRepository(this.backend);

  final FakeDeliveryLifecycleRepository backend;
  final List<LifecycleMutation> mutations = [];

  List<LifecycleMutation> mutationsOf(String operation) =>
      mutations.where((m) => m.operation == operation).toList();

  @override
  Future<DeliveryResult<DeliveryLifecycleAck?>> getActiveDelivery() =>
      backend.getActiveDelivery();

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmPickup({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? notes,
  }) {
    mutations.add(
      LifecycleMutation(
        operation: 'confirmPickup',
        deliveryId: deliveryId,
        aggregateVersion: aggregateVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
    return backend.confirmPickup(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      notes: notes,
    );
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> reportAutomaticArrival({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required ArrivalEvidence evidence,
  }) {
    mutations.add(
      LifecycleMutation(
        operation: 'reportAutomaticArrival',
        deliveryId: deliveryId,
        aggregateVersion: aggregateVersion,
        idempotencyKey: idempotencyKey,
        clientEventId: evidence.clientEventId,
      ),
    );
    return backend.reportAutomaticArrival(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      evidence: evidence,
    );
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
  }) {
    mutations.add(
      LifecycleMutation(
        operation: 'confirmDelivery',
        deliveryId: deliveryId,
        aggregateVersion: aggregateVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
    return backend.confirmDelivery(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> cancelDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? reasonCode,
  }) {
    mutations.add(
      LifecycleMutation(
        operation: 'cancelDelivery',
        deliveryId: deliveryId,
        aggregateVersion: aggregateVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
    return backend.cancelDelivery(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      reasonCode: reasonCode,
    );
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> reportIssue({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required String code,
    String? notes,
  }) {
    mutations.add(
      LifecycleMutation(
        operation: 'reportIssue',
        deliveryId: deliveryId,
        aggregateVersion: aggregateVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
    return backend.reportIssue(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      code: code,
      notes: notes,
    );
  }

  @override
  Future<DeliveryResult<CustomerContact>> getCustomerContact({
    required String deliveryId,
    required String deliveryState,
  }) => backend.getCustomerContact(
    deliveryId: deliveryId,
    deliveryState: deliveryState,
  );

  @override
  CustomerContact? get cachedCustomerContact => backend.cachedCustomerContact;

  @override
  void clearCustomerContact({String? deliveryId}) =>
      backend.clearCustomerContact(deliveryId: deliveryId);

  @override
  Future<DeliveryResult<BatchSummary?>> getActiveBatch() =>
      backend.getActiveBatch();

  @override
  Future<DeliveryResult<BatchSummary>> getBatch(String batchId) =>
      backend.getBatch(batchId);
}

typedef Step5d2Harness = ({
  FakeDeliveryLifecycleRepository backend,
  RecordingLifecycleRepository lifecycle,
  FakeDeliveryAssignmentRepository assignments,
  FakeDeliveryCommandRepository commands,
});

CustomerContact sampleContact({String deliveryId = 'asg-1'}) => CustomerContact(
  deliveryId: deliveryId,
  name: 'Customer Contact',
  phoneNumber: '+966500000001',
  availableUntil: DateTime.utc(2026, 7, 30, 12),
);

ArrivalEvidence sampleEvidence({String clientEventId = 'evt-geofence-1'}) =>
    ArrivalEvidence(
      clientEventId: clientEventId,
      capturedAt: DateTime.utc(2026, 7, 30, 9),
      latitude: 24.7743,
      longitude: 46.7386,
      accuracyMeters: 8,
      policyVersion: 'geofence-v1',
    );

Step5d2Harness makeHarness({
  DeliveryAssignment? active,
  String backendState =
      CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
  int backendVersion = 0,
  bool withContact = false,
}) {
  final backend = FakeDeliveryLifecycleRepository();
  if (active != null) {
    backend.seedActive(
      DeliveryLifecycleAck(
        deliveryId: active.assignmentId,
        state: backendState,
        aggregateVersion: backendVersion,
        updatedAt: DateTime.utc(2026, 7, 30, 8),
      ),
    );
  }
  if (withContact) {
    backend.seedContact(
      sampleContact(deliveryId: active?.assignmentId ?? 'asg-1'),
    );
  }
  return (
    backend: backend,
    lifecycle: RecordingLifecycleRepository(backend),
    assignments: FakeDeliveryAssignmentRepository(active: active),
    commands: FakeDeliveryCommandRepository(),
  );
}

/// Every factory builds a FRESH use-case instance over the SAME repositories,
/// which is exactly what an app restart produces (state lives in the
/// repositories / command ledger, not in the use cases).
ConfirmPickupRemote confirmPickupOf(Step5d2Harness h) => ConfirmPickupRemote(
  lifecycleRepository: h.lifecycle,
  assignmentRepository: h.assignments,
  commandRepository: h.commands,
);

ReportAutomaticArrivalRemote reportArrivalOf(Step5d2Harness h) =>
    ReportAutomaticArrivalRemote(
      lifecycleRepository: h.lifecycle,
      assignmentRepository: h.assignments,
      commandRepository: h.commands,
    );

ConfirmDeliveryRemote confirmDeliveryOf(Step5d2Harness h) =>
    ConfirmDeliveryRemote(
      lifecycleRepository: h.lifecycle,
      assignmentRepository: h.assignments,
      commandRepository: h.commands,
    );

CancelDeliveryRemote cancelDeliveryOf(Step5d2Harness h) => CancelDeliveryRemote(
  lifecycleRepository: h.lifecycle,
  assignmentRepository: h.assignments,
  commandRepository: h.commands,
);

GetCustomerContact getContactOf(Step5d2Harness h) => GetCustomerContact(
  lifecycleRepository: h.lifecycle,
  assignmentRepository: h.assignments,
);

ReplayPendingDeliveryCommands replayOf(Step5d2Harness h) =>
    ReplayPendingDeliveryCommands(
      commandRepository: h.commands,
      assignmentRepository: h.assignments,
      confirmPickup: confirmPickupOf(h),
      reportArrival: reportArrivalOf(h),
      confirmDelivery: confirmDeliveryOf(h),
    );

DeliveryAssignment waitingPickupAssignment() => sampleAssignment(
  workflowStage: DriverWorkflowStage.waitingPickup,
  status: DeliveryStatus.accepted,
  serverRevision: '0',
);

DeliveryAssignment enRouteAssignment() => sampleAssignment(
  workflowStage: DriverWorkflowStage.navToCustomer,
  status: DeliveryStatus.pickedUp,
  serverRevision: '0',
);

DeliveryAssignment verifyingAssignment() => sampleAssignment(
  workflowStage: DriverWorkflowStage.verifying,
  status: DeliveryStatus.pickedUp,
  serverRevision: '0',
);

// ---------------------------------------------------------------------------
// PII payload scanning (STEP 5D-2 acceptance: PII persistent storage == 0).
// ---------------------------------------------------------------------------

const _forbiddenPayloadKeys = {
  'name',
  'customername',
  'customer_name',
  'phone',
  'phonenumber',
  'phone_number',
  'customerphone',
  'customer_phone',
  'contact',
  'customercontact',
  'customer_contact',
};

final _saudiPhonePattern = RegExp(r'\+9665\d{8}');

bool _nodeContainsCustomerPii(Object? node) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString().toLowerCase();
      if (_forbiddenPayloadKeys.contains(key)) return true;
      if (_nodeContainsCustomerPii(entry.value)) return true;
    }
    return false;
  }
  if (node is List) return node.any(_nodeContainsCustomerPii);
  if (node is String) {
    return _saudiPhonePattern.hasMatch(node) ||
        node.contains('Customer Contact');
  }
  return false;
}

/// True when any [LocalDeliveryCommand] payload in the ledger carries
/// customer contact fields or synthetic contact values.
bool commandLedgerContainsCustomerPii(FakeDeliveryCommandRepository commands) =>
    commands.commands.values.any(
      (command) => _nodeContainsCustomerPii(command.payload),
    );

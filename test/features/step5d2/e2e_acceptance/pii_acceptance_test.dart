/// STEP 5D-2 acceptance — customer PII lifecycle.
///
/// Contact is HIDDEN before pickup and while pending sync, ALLOWED only for
/// the current customer after the Backend acknowledgment, HIDDEN for
/// upcoming customers, CLEARED after delivery / cancellation / logout /
/// session expiration, and NEVER written to persistent storage (the Local
/// Command Ledger payloads stay PII-free).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/batch_summary_wire.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_lifecycle_wire.dart';
import 'package:saeq_driver/features/delivery/data/remote/customer_contact_memory_cache.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_lifecycle_remote.dart';
import 'package:saeq_driver/features/delivery/data/repositories/remote_delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import '../contract_wire/contract_wire_harness.dart';
import 'step5d2_e2e_helpers.dart';

void main() {
  test('before pickup: contact is HIDDEN even when cached', () async {
    final h = makeHarness(active: waitingPickupAssignment(), withContact: true);

    final result = await getContactOf(h)(driverId: 'drv-1');
    expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
    // The denial also wipes the memory copy.
    expect(h.backend.cachedCustomerContact, isNull);
  });

  test('during pending pickup sync: contact is HIDDEN', () async {
    final h = makeHarness(active: waitingPickupAssignment(), withContact: true);
    await confirmPickupOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-pickup',
      connectivityOnline: false,
    );
    expect(h.assignments.active?.pendingSync, isTrue);

    final result = await getContactOf(h)(driverId: 'drv-1');
    expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
    expect(h.backend.cachedCustomerContact, isNull);
  });

  test('current customer after Backend ack: contact is ALLOWED', () async {
    final h = makeHarness(active: waitingPickupAssignment(), withContact: true);

    final pickup = await confirmPickupOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-ack',
    );
    expect(pickup.isSuccess, isTrue);
    expect(
      pickup.valueOrNull?.workflowStage,
      DriverWorkflowStage.navToCustomer,
    );

    h.backend.seedContact(sampleContact());
    final result = await getContactOf(h)(driverId: 'drv-1');
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.name, 'Customer Contact');
    expect(result.valueOrNull?.phoneNumber, '+966500000001');
  });

  group('upcoming customer: contact is HIDDEN', () {
    test('BatchSummaryWire flags upcoming stops that carry contact '
        'fields', () {
      final wire = BatchSummaryWire.fromJson(
        batchSummaryJson(
          stops: [
            batchStopJson(),
            batchStopJson(sequence: 2, label: 'Stop 2')
              ..['phoneNumber'] = '+966500000009'
              ..['customerName'] = 'Upcoming Customer',
          ],
        ),
      );
      expect(wire.upcomingStopsHaveContactFields, isTrue);
    });

    test('RemoteDeliveryLifecycleRepository denies leaking batch '
        'payloads', () async {
      final h = ContractWireHarness();
      final repo = RemoteDeliveryLifecycleRepository(
        remote: HttpDeliveryLifecycleRemote(
          api: h.api,
          contactCache: CustomerContactMemoryCache(),
        ),
      );
      h.enqueue(
        200,
        batchSummaryJson(
          stops: [
            batchStopJson(),
            batchStopJson(sequence: 2, label: 'Stop 2')
              ..['phoneNumber'] = '+966500000009',
          ],
        ),
      );

      final result = await repo.getActiveBatch();
      expect(result.failureOrNull, isA<DeliverySecurityPolicyDenied>());
    });
  });

  test('after delivery: contact is CLEARED', () async {
    final h = makeHarness(
      active: verifyingAssignment(),
      backendState: CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
      withContact: true,
    );
    expect(h.backend.cachedCustomerContact, isNotNull);

    final result = await confirmDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-delivered',
    );
    expect(result.isSuccess, isTrue);
    expect(h.backend.cachedCustomerContact, isNull);

    final after = await getContactOf(h)(driverId: 'drv-1');
    expect(after.failureOrNull, isA<DeliveryContactNotAvailable>());
  });

  test('after cancellation: contact is CLEARED', () async {
    final h = makeHarness(
      active: enRouteAssignment(),
      backendState: CanonicalDeliveryStates.enRouteToCustomer,
      withContact: true,
    );
    expect(h.backend.cachedCustomerContact, isNotNull);

    final result = await cancelDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-cancel',
      reasonCode: 'customer_request',
    );
    expect(result.isSuccess, isTrue);
    expect(h.backend.cachedCustomerContact, isNull);
    expect(h.assignments.active, isNull);
  });

  test('after logout: memory cache is CLEARED via '
      'onLogoutOrSessionExpired', () {
    final h = ContractWireHarness();
    final cache = CustomerContactMemoryCache()
      ..set(CustomerContactWire.fromJson(customerContactJson()));
    final remote = HttpDeliveryLifecycleRemote(api: h.api, contactCache: cache);
    expect(cache.current, isNotNull);

    remote.onLogoutOrSessionExpired();
    expect(cache.current, isNull);
  });

  test('after session expiration cleanup: memory cache is CLEARED', () {
    final h = ContractWireHarness();
    final cache = CustomerContactMemoryCache()
      ..set(CustomerContactWire.fromJson(customerContactJson()));
    final remote = HttpDeliveryLifecycleRemote(api: h.api, contactCache: cache);

    // Session expiration triggers the same memory-only cleanup as logout.
    remote.onLogoutOrSessionExpired();
    expect(cache.current, isNull);
    // Repeated cleanup stays safe.
    remote.onLogoutOrSessionExpired();
    expect(cache.current, isNull);
  });

  test('PII persistent storage is 0: the full offline→replay lifecycle '
      'never writes contact fields into the command ledger', () async {
    final h = makeHarness(active: waitingPickupAssignment(), withContact: true);

    // Pickup offline → replay.
    await confirmPickupOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-flow-pickup',
      notes: 'gate 3',
      connectivityOnline: false,
    );
    expect((await replayOf(h)(driverId: 'drv-1')).isSuccess, isTrue);

    // Contact loaded (memory-only) while en route.
    h.backend.seedContact(sampleContact());
    final contact = await getContactOf(h)(driverId: 'drv-1');
    expect(contact.isSuccess, isTrue);

    // Automatic arrival offline → replay.
    await reportArrivalOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-flow-arrival',
      evidence: sampleEvidence(clientEventId: 'evt-pii-flow-1'),
      connectivityOnline: false,
    );
    expect((await replayOf(h)(driverId: 'drv-1')).isSuccess, isTrue);

    // Delivery confirmation offline → replay.
    await confirmDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-pii-flow-confirm',
      connectivityOnline: false,
    );
    expect((await replayOf(h)(driverId: 'drv-1')).isSuccess, isTrue);
    expect(h.assignments.active?.workflowStage, DriverWorkflowStage.summary);

    // The ledger holds the replayed commands — but zero customer PII.
    expect(h.commands.commands, isNotEmpty);
    for (final command in h.commands.commands.values) {
      expect(command.status, LocalDeliveryCommandStatus.completed);
    }
    expect(commandLedgerContainsCustomerPii(h.commands), isFalse);

    // Memory-only contact is gone after the acknowledged completion.
    expect(h.backend.cachedCustomerContact, isNull);
  });

  test('PII scanner control: a poisoned payload IS detected', () async {
    final h = makeHarness();
    await h.commands.save(
      LocalDeliveryCommand(
        commandId: 'cmd-poisoned',
        driverId: 'drv-1',
        targetId: 'asg-1',
        type: LocalDeliveryCommandType.confirmPickup,
        status: LocalDeliveryCommandStatus.pendingSync,
        recordedAt: DateTime.utc(2026, 7, 30, 9),
        payload: const {
          'deliveryId': 'asg-1',
          'customer': {'phoneNumber': '+966500000001'},
        },
      ),
    );
    expect(commandLedgerContainsCustomerPii(h.commands), isTrue);
  });
}

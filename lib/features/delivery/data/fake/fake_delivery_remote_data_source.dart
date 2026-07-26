import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/security_policy_decision.dart';
import '../../domain/entities/delivery_offer_status.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/policies/delivery_offer_transition_decision.dart';
import '../../domain/policies/delivery_offer_transition_policy.dart';
import '../../domain/policies/one_active_offer_policy.dart';
import '../datasources/delivery_remote_data_source.dart';
import '../models/delivery_assignment_model.dart';
import '../models/delivery_offer_model.dart';
import 'fake_delivery_seed.dart';

/// Typed reason codes for [FakeDeliveryRemotePolicy] (ADR-027).
abstract final class FakeDeliveryRemoteReasonCode {
  static const releaseModeDenied = 'releaseModeDenied';
  static const productionEnvironmentDenied = 'productionEnvironmentDenied';
  static const invalidEnvironment = 'invalidEnvironment';
  static const policyConfigurationMissing = 'policyConfigurationMissing';
}

/// Release / production gate for the Fake remote delivery backend (ADR-027).
class FakeDeliveryRemotePolicy {
  const FakeDeliveryRemotePolicy._();

  static const policyVersion = 'phase-2.6.fake-delivery-remote.v1';

  /// Full evaluation. Defaults to deny when inputs are null/unknown.
  static SecurityPolicyDecision evaluate({
    required bool? isReleaseMode,
    required bool? isProductionEnvironment,
  }) {
    if (isReleaseMode == null || isProductionEnvironment == null) {
      return SecurityPolicyDecision.deny(
        policyVersion: policyVersion,
        reasonCodes: const [
          FakeDeliveryRemoteReasonCode.invalidEnvironment,
          FakeDeliveryRemoteReasonCode.policyConfigurationMissing,
        ],
      );
    }

    final reasons = <String>[];
    if (isReleaseMode) {
      reasons.add(FakeDeliveryRemoteReasonCode.releaseModeDenied);
    }
    if (isProductionEnvironment) {
      reasons.add(FakeDeliveryRemoteReasonCode.productionEnvironmentDenied);
    }

    if (reasons.isNotEmpty) {
      return SecurityPolicyDecision.deny(
        policyVersion: policyVersion,
        reasonCodes: reasons,
      );
    }

    return SecurityPolicyDecision.allow(policyVersion: policyVersion);
  }
}

/// In-memory Fake remote delivery backend (PHASE 2.6 / ADR-027).
///
/// Simulates Backend authority for offer fetch / accept / reject:
/// - Deterministic offers from [FakeDeliverySeed]
/// - [DeliveryOfferTransitionPolicy] + [OneActiveOfferPolicy]
/// - Server-generated assignment ids
/// - Configurable latency (default 300 ms; use [Duration.zero] in tests)
///
/// Throws [DeliveryFailure] on rule violations (caught by
/// [RemoteDeliveryOfferRepository]). Not constructible in Release / Production.
class FakeDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  /// Creates a Fake remote datasource.
  ///
  /// Security:
  /// - Hard [kReleaseMode] guard (not injectable).
  /// - Production blocked via [FakeDeliveryRemotePolicy] /
  ///   [isProductionEnvironment] (injectable for denial tests only).
  FakeDeliveryRemoteDataSource({
    FakeDeliverySeed? seed,
    this.networkLatency = const Duration(milliseconds: 300),
    DateTime Function()? clock,
    bool Function()? isProductionEnvironment,
    DeliveryOfferTransitionPolicy? transitionPolicy,
    OneActiveOfferPolicy? oneActiveOfferPolicy,
  }) : _seed = seed ?? const FakeDeliverySeed(),
       _clock = clock ?? DateTime.now,
       _transitionPolicy =
           transitionPolicy ?? const DeliveryOfferTransitionPolicy(),
       _oneActiveOfferPolicy =
           oneActiveOfferPolicy ?? const OneActiveOfferPolicy() {
    if (kReleaseMode) {
      throw StateError(
        'Fake delivery remote is not permitted in release builds.',
      );
    }

    final decision = FakeDeliveryRemotePolicy.evaluate(
      isReleaseMode: false,
      isProductionEnvironment:
          (isProductionEnvironment ?? _defaultIsProductionEnvironment)(),
    );
    if (!decision.allowed) {
      throw StateError(
        'FakeDeliveryRemoteDataSource denied by ${decision.policyVersion}: '
        '${decision.reasonCodes.join(',')}',
      );
    }

    if (networkLatency.isNegative) {
      throw ArgumentError.value(
        networkLatency,
        'networkLatency',
        'cannot be negative',
      );
    }
  }

  static bool _defaultIsProductionEnvironment() => AppConfig.isProduction;

  final FakeDeliverySeed _seed;
  final Duration networkLatency;
  final DateTime Function() _clock;
  final DeliveryOfferTransitionPolicy _transitionPolicy;
  final OneActiveOfferPolicy _oneActiveOfferPolicy;

  /// Debug-only pause after reject before [FakeDeliverySeed.autoIssueOnFetch]
  /// mints the next offer (observable empty state for Alpha testing).
  static const rejectReissueCooldown = Duration(seconds: 8);

  final Map<String, _DriverRemoteState> _byDriver = {};
  final Map<String, StreamController<DeliveryOfferModel?>> _watchControllers =
      {};
  final Map<String, DateTime> _rejectCooldownUntil = {};
  final Map<String, Timer> _reissueTimers = {};

  /// Disposes watch streams and pending re-issue timers. Safe to call
  /// multiple times.
  void dispose() {
    for (final timer in _reissueTimers.values) {
      timer.cancel();
    }
    _reissueTimers.clear();
    for (final controller in _watchControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _watchControllers.clear();
    _rejectCooldownUntil.clear();
  }

  @override
  Future<List<DeliveryOfferModel>> fetchOffers({
    required String driverId,
  }) async {
    await _delay();
    final id = _requireDriverId(driverId);
    final state = _stateFor(id);
    _refreshExpiry(state, id);

    if (state.activeOffer == null && _seed.autoIssueOnFetch) {
      final cooldownUntil = _rejectCooldownUntil[id];
      final inCooldown =
          cooldownUntil != null && _clock().toUtc().isBefore(cooldownUntil);
      if (!inCooldown) {
        _rejectCooldownUntil.remove(id);
        _issueOffer(state, id);
        if (kDebugMode) {
          debugPrint(
            'FakeDeliveryRemote: auto-issued offer on fetch '
            '(visibleCount=${_visibleOffers(state).length})',
          );
        }
      } else if (kDebugMode) {
        debugPrint('FakeDeliveryRemote: skip auto-issue (reject cooldown)');
      }
    }

    return _visibleOffers(state);
  }

  @override
  Stream<DeliveryOfferModel?> watchActiveOffer({required String driverId}) {
    final id = driverId.trim();
    final controller = _watchControllers.putIfAbsent(
      id,
      () => StreamController<DeliveryOfferModel?>.broadcast(),
    );
    // Synchronous snapshot for late subscribers is not guaranteed; callers
    // should also fetchOffers. Emit current when first listened if possible.
    scheduleMicrotask(() {
      if (controller.isClosed) return;
      final state = _byDriver[id];
      controller.add(_activeWatchValue(state));
    });
    return controller.stream;
  }

  @override
  Future<DeliveryAssignmentModel> acceptOffer({
    required String driverId,
    required String offerId,
    required String idempotencyKey,
    String? revision,
    String? correlationId,
  }) async {
    await _delay();
    final id = _requireDriverId(driverId);
    final oid = offerId.trim();
    final key = idempotencyKey.trim();
    if (oid.isEmpty) {
      throw const DeliveryOfferNotFound();
    }
    if (key.isEmpty) {
      throw const DeliverySecurityPolicyDenied(
        'Accept requires a non-empty idempotency key.',
      );
    }

    final state = _stateFor(id);
    final cached = state.acceptByIdempotency[key];
    if (cached != null) {
      if (cached.offerId != oid || cached.driverId != id) {
        throw const DeliveryConflict(
          'Idempotency key is bound to a different accept.',
        );
      }
      if (kDebugMode) {
        debugPrint('FakeDeliveryRemote: acceptOffer idempotent replay');
      }
      return cached;
    }

    final offer = state.activeOffer;
    if (offer == null || offer.offerId != oid) {
      throw const DeliveryOfferNotFound();
    }
    if (offer.driverId != id) {
      throw const DeliverySecurityPolicyDenied();
    }

    final domainOffer = offer.toEntity();
    if (domainOffer.isExpiredAt(_clock().toUtc())) {
      _expireAndClear(state, id);
      throw const DeliveryOfferExpired();
    }

    if (revision != null &&
        revision.trim().isNotEmpty &&
        offer.revision != null &&
        offer.revision != revision) {
      throw const DeliveryConflict();
    }

    _assertTransition(domainOffer.status, DeliveryOfferStatus.accepting);
    _setOfferStatus(state, id, DeliveryOfferStatus.accepting);

    _assertTransition(
      DeliveryOfferStatus.accepting,
      DeliveryOfferStatus.accepted,
    );

    final assignment = _seed.buildAssignment(
      offer: offer,
      acceptedAt: _clock().toUtc(),
    );
    state.acceptByIdempotency[key] = assignment;
    state.lastAssignment = assignment;
    _setOfferStatus(state, id, DeliveryOfferStatus.accepted);
    // Terminal success clears the decision window (accepted → none).
    _assertTransition(DeliveryOfferStatus.accepted, DeliveryOfferStatus.none);
    state.activeOffer = null;
    _emitWatch(id, null);
    if (kDebugMode) {
      debugPrint('FakeDeliveryRemote: acceptOffer succeeded');
    }
    return assignment;
  }

  @override
  Future<void> rejectOffer({
    required String driverId,
    required String offerId,
    String? idempotencyKey,
    String? reasonCode,
    String? correlationId,
  }) async {
    await _delay();
    final id = _requireDriverId(driverId);
    final oid = offerId.trim();
    if (oid.isEmpty) {
      throw const DeliveryOfferNotFound();
    }

    final state = _stateFor(id);
    final offer = state.activeOffer;
    if (offer == null || offer.offerId != oid) {
      throw const DeliveryOfferNotFound();
    }
    if (offer.driverId != id) {
      throw const DeliverySecurityPolicyDenied();
    }

    final domainOffer = offer.toEntity();
    if (domainOffer.isExpiredAt(_clock().toUtc())) {
      _expireAndClear(state, id);
      throw const DeliveryOfferExpired();
    }

    _assertTransition(domainOffer.status, DeliveryOfferStatus.rejecting);
    _setOfferStatus(state, id, DeliveryOfferStatus.rejecting);

    _assertTransition(
      DeliveryOfferStatus.rejecting,
      DeliveryOfferStatus.rejected,
    );
    _setOfferStatus(state, id, DeliveryOfferStatus.rejected);

    _assertTransition(DeliveryOfferStatus.rejected, DeliveryOfferStatus.none);
    state.activeOffer = null;
    _armRejectCooldown(id);
    _emitWatch(id, null);
    if (kDebugMode) {
      debugPrint('FakeDeliveryRemote: rejectOffer succeeded');
    }
  }

  void _armRejectCooldown(String driverId) {
    _rejectCooldownUntil[driverId] = _clock().toUtc().add(
      rejectReissueCooldown,
    );
    _reissueTimers[driverId]?.cancel();
    // Wall-clock timer so Alpha devices see a new offer without a manual
    // refresh after the empty cooldown. Tests that advance an injected clock
    // still re-issue on the next [fetchOffers] once cooldown has elapsed.
    _reissueTimers[driverId] = Timer(rejectReissueCooldown, () {
      _rejectCooldownUntil.remove(driverId);
      final state = _byDriver[driverId];
      if (state == null || state.activeOffer != null) return;
      if (!_seed.autoIssueOnFetch) return;
      _issueOffer(state, driverId);
      _emitWatch(driverId, state.activeOffer);
      if (kDebugMode) {
        debugPrint(
          'FakeDeliveryRemote: auto-issued offer after reject cooldown',
        );
      }
    });
  }

  Future<void> _delay() async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }
  }

  String _requireDriverId(String driverId) {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw const DeliveryUnauthenticated();
    }
    return id;
  }

  _DriverRemoteState _stateFor(String driverId) {
    return _byDriver.putIfAbsent(driverId, _DriverRemoteState.new);
  }

  void _issueOffer(_DriverRemoteState state, String driverId) {
    state.sequence += 1;
    final offer = _seed.buildOffer(
      driverId: driverId,
      sequence: state.sequence,
      now: _clock().toUtc(),
    );

    // Enforce one-active-offer before publishing.
    final candidate = offer.toEntity();
    final current = state.activeOffer?.toEntity();
    if (!_oneActiveOfferPolicy.allowsIncoming(
      current: current,
      candidate: candidate,
    )) {
      throw const DeliveryActiveOfferConflict();
    }

    state.activeOffer = offer;
    _emitWatch(driverId, offer);
  }

  List<DeliveryOfferModel> _visibleOffers(_DriverRemoteState state) {
    final offer = state.activeOffer;
    if (offer == null) return const [];

    final domain = offer.toEntity();
    if (!domain.status.isActive &&
        domain.status != DeliveryOfferStatus.offered) {
      return const [];
    }

    final enforced = _oneActiveOfferPolicy.enforce([domain]);
    return [
      for (final entity in enforced) DeliveryOfferModel.fromEntity(entity),
    ];
  }

  void _refreshExpiry(_DriverRemoteState state, String driverId) {
    final offer = state.activeOffer;
    if (offer == null) return;
    final domain = offer.toEntity();
    if (!domain.status.isActive &&
        domain.status != DeliveryOfferStatus.offered) {
      return;
    }
    if (!domain.isExpiredAt(_clock().toUtc())) return;
    _expireAndClear(state, driverId);
  }

  /// Marks the active offer expired (when allow-listed) and clears the window.
  void _expireAndClear(_DriverRemoteState state, String driverId) {
    final offer = state.activeOffer;
    if (offer == null) return;
    final current = offer.toEntity().status;
    final decision = _transitionPolicy.evaluate(
      DeliveryOfferTransitionContext(
        current: current,
        requested: DeliveryOfferStatus.expired,
      ),
    );
    if (decision.allowed) {
      _setOfferStatus(state, driverId, DeliveryOfferStatus.expired);
    }
    state.activeOffer = null;
    _emitWatch(driverId, null);
  }

  void _setOfferStatus(
    _DriverRemoteState state,
    String driverId,
    DeliveryOfferStatus status,
  ) {
    final current = state.activeOffer;
    if (current == null) return;
    state.activeOffer = DeliveryOfferModel(
      offerId: current.offerId,
      driverId: current.driverId,
      status: status.name,
      order: current.order,
      issuedAt: current.issuedAt,
      expiresAt: current.expiresAt,
      revision: current.revision,
      correlationId: current.correlationId,
    );
    if (status.isActive || status == DeliveryOfferStatus.offered) {
      _emitWatch(driverId, state.activeOffer);
    }
  }

  void _assertTransition(
    DeliveryOfferStatus current,
    DeliveryOfferStatus requested,
  ) {
    final decision = _transitionPolicy.evaluate(
      DeliveryOfferTransitionContext(current: current, requested: requested),
    );
    if (!decision.allowed) {
      throw decision.failure ?? const InvalidDeliveryOfferTransition();
    }
  }

  DeliveryOfferModel? _activeWatchValue(_DriverRemoteState? state) {
    final offer = state?.activeOffer;
    if (offer == null) return null;
    final status = offer.toEntity().status;
    if (status.isActive || status == DeliveryOfferStatus.offered) {
      return offer;
    }
    return null;
  }

  void _emitWatch(String driverId, DeliveryOfferModel? offer) {
    final controller = _watchControllers[driverId];
    if (controller == null || controller.isClosed) return;
    controller.add(offer);
  }
}

class _DriverRemoteState {
  DeliveryOfferModel? activeOffer;
  DeliveryAssignmentModel? lastAssignment;
  int sequence = 0;
  final Map<String, DeliveryAssignmentModel> acceptByIdempotency = {};
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../data/fake/fake_delivery_history_repository.dart';
import '../../domain/entities/delivery_history_item.dart';
import '../../domain/repositories/delivery_history_repository.dart';

final deliveryHistoryRepositoryProvider = Provider<DeliveryHistoryRepository?>((
  ref,
) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // Tests without AppConfig.init still get Fake seed.
  }
  return FakeDeliveryHistoryRepository.forApp();
});

class HistoryControllerState {
  const HistoryControllerState({
    this.items = const [],
    this.filter = DeliveryHistoryFilter.all,
    this.loading = false,
    this.failureMessage,
  });

  final List<DeliveryHistoryItem> items;
  final DeliveryHistoryFilter filter;
  final bool loading;
  final String? failureMessage;

  HistoryControllerState copyWith({
    List<DeliveryHistoryItem>? items,
    DeliveryHistoryFilter? filter,
    bool? loading,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return HistoryControllerState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      failureMessage: clearFailure
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}

class HistoryController extends Notifier<HistoryControllerState> {
  @override
  HistoryControllerState build() {
    Future.microtask(load);
    return const HistoryControllerState(loading: true);
  }

  DeliveryHistoryRepository? get _repo =>
      ref.read(deliveryHistoryRepositoryProvider);

  Future<void> load() async {
    final repo = _repo;
    if (repo == null) {
      state = const HistoryControllerState(
        failureMessage: 'unavailable',
        loading: false,
      );
      return;
    }
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final items = await repo.listHistory(filter: state.filter);
      if (!ref.mounted) return;
      state = state.copyWith(items: items, loading: false);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, failureMessage: 'load_failed');
    }
  }

  Future<void> setFilter(DeliveryHistoryFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    await load();
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryControllerState>(
      HistoryController.new,
    );

final historyDetailProvider =
    FutureProvider.family<DeliveryHistoryItem?, String>((ref, id) async {
      final repo = ref.watch(deliveryHistoryRepositoryProvider);
      if (repo == null) return null;
      return repo.getById(id);
    });

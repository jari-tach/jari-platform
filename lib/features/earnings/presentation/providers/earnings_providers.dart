import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../data/fake/fake_earnings_repository.dart';
import '../../domain/entities/earnings_period.dart';
import '../../domain/repositories/earnings_repository.dart';

final earningsRepositoryProvider = Provider<EarningsRepository?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {}
  return FakeEarningsRepository.forApp();
});

class EarningsControllerState {
  const EarningsControllerState({
    this.items = const [],
    this.filter = EarningsFilter.all,
    this.loading = false,
    this.failureMessage,
  });

  final List<EarningsPeriod> items;
  final EarningsFilter filter;
  final bool loading;
  final String? failureMessage;

  EarningsControllerState copyWith({
    List<EarningsPeriod>? items,
    EarningsFilter? filter,
    bool? loading,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return EarningsControllerState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      failureMessage: clearFailure
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}

class EarningsController extends Notifier<EarningsControllerState> {
  @override
  EarningsControllerState build() {
    Future.microtask(load);
    return const EarningsControllerState(loading: true);
  }

  EarningsRepository? get _repo => ref.read(earningsRepositoryProvider);

  Future<void> load() async {
    final repo = _repo;
    if (repo == null) {
      state = const EarningsControllerState(
        failureMessage: 'unavailable',
        loading: false,
      );
      return;
    }
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final items = await repo.listPeriods(filter: state.filter);
      if (!ref.mounted) return;
      state = state.copyWith(items: items, loading: false);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, failureMessage: 'load_failed');
    }
  }

  Future<void> setFilter(EarningsFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    await load();
  }
}

final earningsControllerProvider =
    NotifierProvider<EarningsController, EarningsControllerState>(
      EarningsController.new,
    );

final earningsDetailProvider = FutureProvider.family<EarningsPeriod?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(earningsRepositoryProvider);
  if (repo == null) return null;
  return repo.getById(id);
});

import '../entities/earnings_period.dart';

abstract interface class EarningsRepository {
  Future<List<EarningsPeriod>> listPeriods({
    EarningsFilter filter = EarningsFilter.all,
  });

  Future<EarningsPeriod?> getById(String id);
}

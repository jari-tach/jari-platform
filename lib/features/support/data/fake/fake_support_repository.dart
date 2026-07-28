import '../../../../core/config/app_config.dart';
import '../../domain/entities/support_config.dart';
import '../../domain/repositories/support_repository.dart';

/// Fake Alpha support repository.
///
/// Returns [SupportConfig.unavailable] so production-like builds never show
/// invented phone numbers or emails. Debug-only sample contacts are intentionally
/// omitted — unavailable state drives the UI until Backend wiring lands.
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({bool Function()? isProductionEnvironment})
    : _isProductionEnvironment =
          isProductionEnvironment ?? (() => AppConfig.isProduction);

  final bool Function() _isProductionEnvironment;

  factory FakeSupportRepository.forApp() {
    return FakeSupportRepository(
      isProductionEnvironment: () {
        try {
          return AppConfig.isProduction;
        } catch (_) {
          return false;
        }
      },
    );
  }

  @override
  Future<SupportConfig> getSupportConfig() async {
    if (_isProductionEnvironment()) {
      throw StateError('FakeSupportRepository must not run in production.');
    }
    return SupportConfig.unavailable;
  }
}

import '../entities/support_config.dart';

abstract class SupportRepository {
  Future<SupportConfig> getSupportConfig();
}

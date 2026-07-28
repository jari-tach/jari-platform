import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../data/fake/fake_support_repository.dart';
import '../../domain/entities/support_config.dart';
import '../../domain/repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {}
  return FakeSupportRepository.forApp();
});

final supportConfigProvider = FutureProvider<SupportConfig>((ref) async {
  final repository = ref.watch(supportRepositoryProvider);
  if (repository == null) return SupportConfig.unavailable;
  return repository.getSupportConfig();
});

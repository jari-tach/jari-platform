import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) => AppRouter.router);

final appThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

final appLocaleProvider = Provider<Locale>((ref) => const Locale('ar'));

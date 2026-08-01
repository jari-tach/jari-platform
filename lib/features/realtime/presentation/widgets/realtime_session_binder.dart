import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/realtime_providers.dart';

/// Keeps [realtimeControllerProvider] alive for the authenticated driver shell
/// so SSE/polling starts after login even before Home/Offers paint.
class RealtimeSessionBinder extends ConsumerWidget {
  const RealtimeSessionBinder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeControllerProvider);
    return child;
  }
}

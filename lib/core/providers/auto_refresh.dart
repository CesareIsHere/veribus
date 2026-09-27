import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Realtime data changes at most every 30 s: pages poll every 15 s while they are open (autoDispose providers
/// stop with them) and the app is in the foreground. No push channel: it would not bring fresher data.
extension AutoRefresh on Ref {
  void refreshEvery([Duration period = const Duration(seconds: 15)]) {
    late Timer timer;
    void schedule() => timer = Timer(period, () {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        invalidateSelf();
      } else {
        schedule();
      }
    });
    schedule();
    onDispose(() => timer.cancel());
  }
}

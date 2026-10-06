import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/services/location_service.dart';
import 'package:veribus/services/location_tracker.dart';

part 'position_provider.g.dart';

/// Tracks the device position while someone watches it, and not in the background (it stops the GPS then).
@riverpod
LocationTracker locationTracker(Ref ref) {
  final tracker = LocationTracker(ref.watch(locationServiceProvider))..start();
  // Coming back from the system settings (GPS turned on, permission granted) lands here.
  final lifecycle = AppLifecycleListener(onResume: tracker.start, onPause: tracker.pause);
  ref.onDispose(() {
    lifecycle.dispose();
    unawaited(tracker.dispose());
  });
  return tracker;
}

/// Live device position, null while it is not available (the app stays usable: RF-02). It comes back by itself when
/// the user turns the GPS on or grants the permission.
@riverpod
Stream<LatLng?> position(Ref ref) => ref.watch(locationTrackerProvider).positions;

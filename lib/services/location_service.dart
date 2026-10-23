import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';

part 'location_service.g.dart';

/// Whether the app can read the position right now, and if not why.
enum LocationAccess { granted, serviceOff, denied, deniedForever }

/// What the persistent notification of a followed journey says (Android).
typedef FollowNotice = ({String title, String text, String channelName});

/// The platform location APIs, nothing more (the position never leaves the phone: RNF-04). The logic that keeps a
/// live position through GPS toggles and permission changes is in `LocationTracker`.
class LocationService {
  /// Fixed position of `MOCK_POSITION` ("lat,lon"), for runs without a GPS: emulator, web, demos.
  LatLng? get mock {
    if (AppConfig.mockPosition.isEmpty) return null;
    final [lat, lon] = AppConfig.mockPosition.split(',').map(double.parse).toList();
    return LatLng(lat, lon);
  }

  Future<LocationAccess> access() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    return switch (await Geolocator.checkPermission()) {
      LocationPermission.denied || LocationPermission.unableToDetermine => LocationAccess.denied,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      LocationPermission.whileInUse || LocationPermission.always => LocationAccess.granted,
    };
  }

  /// Shows the system permission dialog; true when the user granted it.
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  /// The last fix the OS already has: instant, no GPS start-up (null when it has none, or on web).
  Future<LatLng?> lastKnown() async {
    if (kIsWeb) return null;
    final p = await Geolocator.getLastKnownPosition();
    return p == null ? null : LatLng(p.latitude, p.longitude);
  }

  /// Live fixes while someone listens. Errors (service switched off, GPS failure) end the stream: the caller looks again.
  ///
  /// With a [notice], on Android, the GPS runs as a foreground service with a persistent notification that keeps the
  /// app alive and the fixes coming with the screen off. The plugin shares one stream among all listeners and takes its
  /// settings from whoever opens it first, so the notice only counts when nobody is listening yet: the tracker, the
  /// only listener, stops and starts the fixes again when it changes.
  Stream<LatLng> fixes({FollowNotice? notice}) =>
      Geolocator.getPositionStream(locationSettings: _settings(notice)).map((p) => LatLng(p.latitude, p.longitude));

  /// True / false each time the user turns the location service on / off. Never fires where the platform has no such
  /// event (web): the tracker also looks again by itself.
  Stream<bool> serviceEnabled() {
    if (kIsWeb) return const Stream.empty();
    return Geolocator.getServiceStatusStream().map((s) => s == ServiceStatus.enabled);
  }

  /// What the "turn on" button does: asks again when the system still lets it, otherwise opens the settings page
  /// that fixes the actual problem (location service, or the app's permission).
  Future<void> enable() async {
    // Web has no settings page to open: the browser asks for the permission by itself.
    if (kIsWeb) {
      await Geolocator.requestPermission();
      return;
    }
    switch (await access()) {
      case LocationAccess.serviceOff:
        await Geolocator.openLocationSettings();
      case LocationAccess.denied:
        await Geolocator.requestPermission();
      case LocationAccess.deniedForever:
        await Geolocator.openAppSettings();
      case LocationAccess.granted:
        break;
    }
  }

  /// Street-level accuracy: the dot has to sit on the right side of the road, not in the right district.
  static LocationSettings _settings(FollowNotice? notice) => switch (defaultTargetPlatform) {
    TargetPlatform.android when !kIsWeb => AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 3),
      foregroundNotificationConfig: notice == null
          ? null
          : ForegroundNotificationConfig(
              notificationTitle: notice.title,
              notificationText: notice.text,
              notificationChannelName: notice.channelName,
              enableWakeLock: true,
              setOngoing: true,
            ),
    ),
    _ => const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
  };
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => LocationService();

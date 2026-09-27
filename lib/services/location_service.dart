import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';

part 'location_service.g.dart';

/// Device position (the position never leaves the phone: RNF-04).
class LocationService {
  /// Asks for the permission once (RF-04, no intro screens); null when denied or off.
  Future<LatLng?> current() async {
    if (AppConfig.mockPosition case final p when p.isNotEmpty) {
      final [lat, lon] = p.split(',').map(double.parse).toList();
      return LatLng(lat, lon);
    }
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
    );
    return LatLng(p.latitude, p.longitude);
  }

  /// Opens the system settings to grant the permission again (RF-04).
  Future<void> openSettings() => Geolocator.openAppSettings();
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => LocationService();

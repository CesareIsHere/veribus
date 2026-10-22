import 'package:latlong2/latlong.dart';

/// Where a journey goes: an address or a place found by name, or home.
class Place {
  const Place({required this.name, required this.point, this.detail = '', this.isHome = false});

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    name: json['name'] as String,
    detail: json['detail'] as String? ?? '',
    point: LatLng((json['lat'] as num).toDouble(), (json['lon'] as num).toDouble()),
  );

  /// "Via Tuscolana 200", "Colosseo".
  final String name;

  /// Street and neighbourhood under the name, empty when the name says it all.
  final String detail;
  final LatLng point;

  /// The home saved on the phone: its name is the word for home, in the user's language.
  final bool isHome;

  Map<String, dynamic> toJson() => {'name': name, 'detail': detail, 'lat': point.latitude, 'lon': point.longitude};
}

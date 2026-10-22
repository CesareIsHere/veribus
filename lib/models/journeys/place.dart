import 'package:latlong2/latlong.dart';

/// What a place is: it decides the icon in the lists and what the journey says on arrival.
enum PlaceType { place, stop, home, work }

/// Where a journey starts or ends: an address or a place found by name, a stop, or one of the places saved on the
/// phone (home, work).
class Place {
  const Place({required this.name, required this.point, this.detail = '', this.type = PlaceType.place});

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    name: json['name'] as String,
    detail: json['detail'] as String? ?? '',
    point: LatLng((json['lat'] as num).toDouble(), (json['lon'] as num).toDouble()),
    type: PlaceType.values.asNameMap()[json['type']] ?? PlaceType.place,
  );

  /// "Via Tuscolana 200", "Colosseo".
  final String name;

  /// Street and neighbourhood under the name, empty when the name says it all.
  final String detail;
  final LatLng point;
  final PlaceType type;

  /// The place saved as home: its name is the word for home, in the user's language.
  bool get isHome => type == PlaceType.home;

  /// Home or work: saved on the phone, not searched.
  bool get isSaved => type == PlaceType.home || type == PlaceType.work;

  Map<String, dynamic> toJson() => {
    'name': name,
    'detail': detail,
    'lat': point.latitude,
    'lon': point.longitude,
    'type': type.name,
  };
}

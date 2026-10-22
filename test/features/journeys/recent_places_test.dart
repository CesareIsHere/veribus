import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/models/journeys/place.dart';

/// The preferences in memory: only what the recent places use.
class _Prefs extends Fake implements SharedPreferencesWithCache {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

Place _place(String name, double lat) => Place(name: name, point: LatLng(lat, 12.5));

void main() {
  test('newest first, the same place once, at most five, kept across launches', () async {
    final prefs = _Prefs();
    ProviderContainer open() => ProviderContainer.test(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);

    final container = open();
    final recent = container.read(recentPlacesProvider.notifier);
    for (var i = 0; i < 6; i++) {
      await recent.add(_place('Place $i', 41.8 + i * 0.01));
    }
    // Found again a few metres away: moves to the top, not added twice.
    await recent.add(_place('Place 3 again', 41.8 + 3 * 0.01 + 0.0001));
    await recent.add(const Place(name: 'Home', point: LatLng(41.9, 12.5), type: PlaceType.home));
    expect(
      [for (final p in container.read(recentPlacesProvider)) p.name],
      ['Place 3 again', 'Place 5', 'Place 4', 'Place 2', 'Place 1'],
    );

    final again = open();
    expect(again.read(recentPlacesProvider).first.name, 'Place 3 again');

    prefs.values['recent_places'] = 'not json';
    expect(open().read(recentPlacesProvider), isEmpty);
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';

part 'map_tile_service.g.dart';

/// The data under the map: OpenFreeMap vector tiles (OpenStreetMap data, no account or key). The app draws them with
/// its own minimal style (`styles/minimal_map_style.dart`).
class MapTileService {
  MapTileService(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// The name the style uses for this source.
  static const source = 'openmaptiles';

  /// The tile URL carries the planet build (`/planet/20261004_113936_pt/...`) and changes every week, so it is read
  /// from the TileJSON, which does not move.
  static const _tileJson = 'https://tiles.openfreemap.org/planet';
  static const _cacheKey = 'map_tile_url';

  Future<TileProviders> providers() async {
    var template = await _fetchTemplate();
    // Offline at launch: the tiles already on disk still have the URL they were downloaded from.
    template ??= _prefs.getString(_cacheKey);
    if (template == null) throw const MapTilesUnavailable();
    return TileProviders({source: NetworkVectorTileProvider(urlTemplate: template, maximumZoom: 14, minimumZoom: 0)});
  }

  Future<String?> _fetchTemplate() async {
    try {
      final response = await http.get(Uri.parse(_tileJson)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final tiles = (jsonDecode(response.body) as Map<String, dynamic>)['tiles'] as List<dynamic>;
      final template = tiles.first as String;
      await _prefs.setString(_cacheKey, template);
      return template;
    } on Exception {
      // Timeout, no network, unexpected body: the caller falls back to the remembered URL.
      return null;
    }
  }
}

class MapTilesUnavailable implements Exception {
  const MapTilesUnavailable();

  @override
  String toString() => 'Map tiles unavailable: offline and none seen before';
}

@Riverpod(keepAlive: true)
MapTileService mapTileService(Ref ref) => MapTileService(ref.watch(sharedPreferencesProvider));

/// The tile sources of the map. Without network the first time there is no map yet: look again until there is.
@Riverpod(keepAlive: true)
Future<TileProviders> mapTiles(Ref ref) async {
  try {
    return await ref.watch(mapTileServiceProvider).providers();
  } on MapTilesUnavailable {
    final retry = Timer(const Duration(seconds: 20), ref.invalidateSelf);
    ref.onDispose(retry.cancel);
    rethrow;
  }
}

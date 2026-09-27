import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';

part 'favorites_notifier.g.dart';

typedef Favorites = ({List<String> stops, List<String> lines});

/// Favorite stops and lines, saved only on the phone (RF-40).
@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  static const _stopsKey = 'favorite_stops';
  static const _linesKey = 'favorite_lines';

  @override
  Favorites build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return (stops: prefs.getStringList(_stopsKey) ?? const [], lines: prefs.getStringList(_linesKey) ?? const []);
  }

  Future<void> toggleStop(String id) async {
    final stops = _toggle(state.stops, id);
    state = (stops: stops, lines: state.lines);
    await ref.read(sharedPreferencesProvider).setStringList(_stopsKey, stops);
  }

  Future<void> toggleLine(String id) async {
    final lines = _toggle(state.lines, id);
    state = (stops: state.stops, lines: lines);
    await ref.read(sharedPreferencesProvider).setStringList(_linesKey, lines);
  }

  static List<String> _toggle(List<String> list, String id) =>
      list.contains(id) ? list.where((x) => x != id).toList() : [...list, id];
}

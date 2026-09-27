import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'favorites_arrivals_provider.g.dart';

/// Arrivals of the favorite stops and vehicles in service on the favorite lines, in one call (RF-41).
@riverpod
Future<Arrivals?> favoritesArrivals(Ref ref) {
  final f = ref.watch(favoritesProvider);
  if (f.stops.isEmpty && f.lines.isEmpty) return Future.value();
  ref.refreshEvery();
  return ref.watch(transitRepositoryProvider).arrivals(f.stops, lineIds: f.lines);
}

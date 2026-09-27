import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'stop_providers.g.dart';

/// Arrivals of one stop, refreshed every 15 s while the panel is open (RF-24).
@riverpod
Future<Arrivals> stopArrivals(Ref ref, String stopId) {
  ref.refreshEvery();
  return ref.watch(transitRepositoryProvider).arrivals([stopId]);
}

@riverpod
Future<List<TimetableDirection>> timetable(Ref ref, String stopId, String lineId, DateTime day) =>
    ref.watch(transitRepositoryProvider).timetable(stopId, lineId, day);

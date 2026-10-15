import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'line_providers.g.dart';

/// One direction of a line with its vehicles, refreshed while the page is open (RF-31).
@riverpod
Future<LineDetail?> lineDetail(Ref ref, String lineId, int directionId) {
  ref.refreshEvery();
  return ref.watch(transitRepositoryProvider).line(lineId, directionId);
}

/// How a slot went on past days of the same kind (weekdays / weekend). It changes once a day: no refresh.
@riverpod
Future<List<TripDay>> tripHistory(
  Ref ref,
  String stopId,
  String lineId,
  int directionId,
  int departureSeconds, {
  required bool weekend,
}) => ref.watch(transitRepositoryProvider).tripHistory(stopId, lineId, directionId, departureSeconds, weekend: weekend);

import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';

/// Network data and realtime arrivals. Implementations: `MockTransitRepository`, `SupabaseTransitRepository`.
abstract interface class ITransitRepository {
  Future<NetworkInfo> networkInfo();

  /// The network data of [info]'s version, from the local cache or downloaded once.
  Future<Network> network(NetworkInfo info);

  /// Arrivals at [stopIds] in the next 60 minutes, plus vehicles in service on [lineIds].
  Future<Arrivals> arrivals(List<String> stopIds, {List<String> lineIds = const []});

  /// Null when the line has no such direction.
  Future<LineDetail?> line(String lineId, int directionId);

  Future<List<TimetableDirection>> timetable(String stopId, String lineId, DateTime day);

  Future<List<ServiceAlert>> alerts();
}

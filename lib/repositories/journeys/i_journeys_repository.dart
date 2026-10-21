import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/transit/network.dart';

/// The journey planner's data. Implementations: `MockJourneysRepository`, `SupabaseJourneysRepository`.
/// Realtime comes from `ITransitRepository.arrivals`, as everywhere else in the app.
abstract interface class IJourneysRepository {
  /// The timetable of [day] (its local date) for the network version of [info], from the local cache or downloaded
  /// once. Null when the nightly import did not build it.
  Future<Timetable?> timetable(NetworkInfo info, DateTime day);
}

import 'package:veribus/models/transit/trip_follow.dart';

/// The trips the signed-in user follows. Implementations: `MockFollowRepository`, `SupabaseFollowRepository`.
abstract interface class IFollowRepository {
  /// All follows, with how today's trip is doing.
  Future<List<TripFollow>> list();

  /// Creates the follow, or updates it when the user already follows that trip. Throws `LimitFailure` past
  /// [TripFollow.maxFollows].
  Future<void> save(TripFollow follow);

  Future<void> setEnabled(String id, {required bool enabled});

  Future<void> remove(String id);
}

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/follow_repository_provider.dart';

part 'follow_providers.g.dart';

/// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
/// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.
@riverpod
class FollowsNotifier extends _$FollowsNotifier {
  @override
  Future<List<TripFollow>> build({bool live = false}) {
    if (live) ref.refreshEvery();
    return ref.watch(followRepositoryProvider).list();
  }

  /// Creates or updates; every list is read again so the pages show what the server holds.
  Future<void> save(TripFollow follow) => _then(() => ref.read(followRepositoryProvider).save(follow));

  Future<void> setEnabled(String id, {required bool enabled}) =>
      _then(() => ref.read(followRepositoryProvider).setEnabled(id, enabled: enabled));

  Future<void> remove(String id) => _then(() => ref.read(followRepositoryProvider).remove(id));

  Future<void> _then(Future<void> Function() change) async {
    await change();
    ref.invalidate(followsProvider);
    await future;
  }
}

/// The keys of the followed trips (`TripFollow.key`): what the timetable marks. Watch it with `select` to rebuild only
/// when one trip flips.
@riverpod
Set<String> followKeys(Ref ref) => {for (final f in ref.watch(followsProvider()).value ?? const <TripFollow>[]) f.key};

/// The follow of a trip, if the user follows it (the form starts from it).
@riverpod
TripFollow? followOf(Ref ref, String key) {
  for (final f in ref.watch(followsProvider()).value ?? const <TripFollow>[]) {
    if (f.key == key) return f;
  }
  return null;
}

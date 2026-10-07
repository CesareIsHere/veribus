import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/follow_repository_provider.dart';

part 'follow_providers.g.dart';

/// The trips the user follows, with today's state, refreshed while a page that shows them is open.
@riverpod
class FollowsNotifier extends _$FollowsNotifier {
  @override
  Future<List<TripFollow>> build() {
    ref.refreshEvery();
    return ref.watch(followRepositoryProvider).list();
  }

  /// Creates or updates; the list is read again so the page shows what the server holds.
  Future<void> save(TripFollow follow) => _then(() => ref.read(followRepositoryProvider).save(follow));

  Future<void> setEnabled(String id, {required bool enabled}) =>
      _then(() => ref.read(followRepositoryProvider).setEnabled(id, enabled: enabled));

  Future<void> remove(String id) => _then(() => ref.read(followRepositoryProvider).remove(id));

  Future<void> _then(Future<void> Function() change) async {
    await change();
    ref.invalidateSelf();
    await future;
  }
}

/// The follow of a trip, if the user follows it (the timetable marks these).
@riverpod
TripFollow? followOf(Ref ref, String key) {
  final follows = ref.watch(followsProvider).value;
  if (follows == null) return null;
  for (final f in follows) {
    if (f.key == key) return f;
  }
  return null;
}

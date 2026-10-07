import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/i_follow_repository.dart';

/// The `trip_follow` table (rows protected by RLS) and `api.my_follows` for today's state.
class SupabaseFollowRepository implements IFollowRepository {
  SupabaseFollowRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<TripFollow>> list() => _call(() async {
    final rows = await _client.schema('api').rpc<dynamic>('my_follows') as List;
    return [for (final r in rows) TripFollow.fromJson(r as Map<String, dynamic>)];
  });

  @override
  Future<void> save(TripFollow follow) => _call(
    () => _client
        .from('trip_follow')
        .upsert(follow.toRow(), onConflict: 'user_id,stop_id,route_id,direction_id,departure_s'),
  );

  @override
  Future<void> setEnabled(String id, {required bool enabled}) =>
      _call(() => _client.from('trip_follow').update({'enabled': enabled}).eq('id', id));

  @override
  Future<void> remove(String id) => _call(() => _client.from('trip_follow').delete().eq('id', id));

  /// SDK errors become [AppFailure]s here, so the rest of the app never sees Supabase types.
  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on PostgrestException catch (e) {
      // The trigger that caps the follows per user.
      if (e.message == 'Too many followed trips') throw const LimitFailure();
      throw ServerFailure(statusCode: int.tryParse(e.code ?? '') ?? 500);
    } on SocketException {
      throw const NetworkFailure();
    } on ClientException {
      throw const NetworkFailure();
    }
  }
}

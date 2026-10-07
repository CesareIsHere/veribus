import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/i_follow_repository.dart';
import 'package:veribus/repositories/supabase_call.dart';

/// The `trip_follow` table (rows protected by RLS) and `api.my_follows` for today's state.
class SupabaseFollowRepository implements IFollowRepository {
  SupabaseFollowRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<TripFollow>> list() => supabaseCall(() async {
    final rows = await _client.schema('api').rpc<dynamic>('my_follows') as List;
    return [for (final r in rows) TripFollow.fromJson(r as Map<String, dynamic>)];
  });

  @override
  Future<void> save(TripFollow follow) => supabaseCall(
    () => _client
        .from('trip_follow')
        .upsert(follow.toRow(), onConflict: 'user_id,stop_id,route_id,direction_id,departure_s'),
  );

  @override
  Future<void> setEnabled(String id, {required bool enabled}) =>
      supabaseCall(() => _client.from('trip_follow').update({'enabled': enabled}).eq('id', id));

  @override
  Future<void> remove(String id) => supabaseCall(() => _client.from('trip_follow').delete().eq('id', id));
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/supabase_call.dart';
import 'package:veribus/repositories/transit/i_transit_repository.dart';

/// `api` schema RPCs (called with the user's JWT) and the public `network` Storage bucket.
class SupabaseTransitRepository implements ITransitRepository {
  SupabaseTransitRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) =>
      supabaseCall(() => _client.schema('api').rpc<dynamic>(fn, params: params));

  @override
  Future<NetworkInfo> networkInfo() async => NetworkInfo.fromJson(await _rpc('network') as Map<String, dynamic>);

  @override
  Future<Network> network(NetworkInfo info) async {
    // Kept in the app support folder until the version changes (not an offline mode: spec 9.2). No cache on web.
    final file = kIsWeb ? null : File('${(await getApplicationSupportDirectory()).path}/network_${info.version}.json');
    if (file != null && file.existsSync()) return await compute(_parse, await file.readAsString());

    final bytes = await supabaseCall(() => _client.storage.from('network').download(info.path));
    final text = utf8.decode(bytes);
    final network = await compute(_parse, text);
    if (file != null) {
      for (final old in file.parent.listSync().whereType<File>().where((f) => f.path.contains('network_'))) {
        old.deleteSync();
      }
      await file.writeAsString(text);
    }
    return network;
  }

  static Network _parse(String text) => Network.fromJson(jsonDecode(text) as Map<String, dynamic>);

  @override
  Future<Arrivals> arrivals(List<String> stopIds, {List<String> lineIds = const []}) async =>
      Arrivals.fromJson(await _rpc('arrivals', {'stop_ids': stopIds, 'route_ids': lineIds}) as Map<String, dynamic>);

  @override
  Future<LineDetail?> line(String lineId, int directionId) async {
    final json = await _rpc('route', {'route_id': lineId, 'direction_id': directionId});
    return json == null ? null : LineDetail.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<TimetableDirection>> timetable(String stopId, String lineId, DateTime day) async {
    final date = day.toIso8601String().substring(0, 10);
    final json = await _rpc('timetable', {'stop_id': stopId, 'route_id': lineId, 'day': date}) as List;
    return [for (final d in json) TimetableDirection.fromJson(d as Map<String, dynamic>)];
  }

  @override
  Future<List<ServiceAlert>> alerts() async => [
    for (final a in await _rpc('alerts') as List) ServiceAlert.fromJson(a as Map<String, dynamic>),
  ];
}

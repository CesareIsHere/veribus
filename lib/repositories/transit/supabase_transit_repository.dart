import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/transit/i_transit_repository.dart';

/// `api` schema RPCs (called with the user's JWT) and the public `network` Storage bucket.
class SupabaseTransitRepository implements ITransitRepository {
  SupabaseTransitRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _rpc(String fn, [Map<String, dynamic>? params]) async =>
      await _call(() => _client.schema('api').rpc<dynamic>(fn, params: params)) as Map<String, dynamic>;

  @override
  Future<NetworkInfo> networkInfo() async => NetworkInfo.fromJson(await _rpc('network'));

  @override
  Future<Network> network(NetworkInfo info) async {
    // Kept in the app support folder until the version changes (not an offline mode: spec 9.2). No cache on web.
    final file = kIsWeb ? null : File('${(await getApplicationSupportDirectory()).path}/network_${info.version}.json');
    if (file != null && file.existsSync()) return await compute(_parse, await file.readAsString());

    final bytes = await _call(() => _client.storage.from('network').download(info.path));
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
      Arrivals.fromJson(await _rpc('arrivals', {'stop_ids': stopIds, 'route_ids': lineIds}));

  @override
  Future<LineDetail?> line(String lineId, int directionId) async {
    final json = await _call(
      () => _client.schema('api').rpc<dynamic>('route', params: {'route_id': lineId, 'direction_id': directionId}),
    );
    return json == null ? null : LineDetail.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<TimetableDirection>> timetable(String stopId, String lineId, DateTime day) async {
    final json = await _call(
      () => _client
          .schema('api')
          .rpc<dynamic>(
            'timetable',
            params: {'stop_id': stopId, 'route_id': lineId, 'day': day.toIso8601String().substring(0, 10)},
          ),
    );
    return [for (final d in json as List) TimetableDirection.fromJson(d as Map<String, dynamic>)];
  }

  @override
  Future<List<ServiceAlert>> alerts() async {
    final json = await _call(() => _client.schema('api').rpc<dynamic>('alerts'));
    return [for (final a in json as List) ServiceAlert.fromJson(a as Map<String, dynamic>)];
  }

  /// SDK errors become [AppFailure]s here, so the rest of the app never sees Supabase types.
  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on PostgrestException catch (e) {
      throw ServerFailure(statusCode: int.tryParse(e.code ?? '') ?? 500);
    } on StorageException catch (e) {
      throw ServerFailure(statusCode: int.tryParse(e.statusCode ?? '') ?? 500);
    } on SocketException {
      throw const NetworkFailure();
    } on ClientException {
      throw const NetworkFailure();
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/journeys/i_journeys_repository.dart';
import 'package:veribus/repositories/supabase_call.dart';

/// Timetables from the public `network` Storage bucket: `journeys/v<version>/<yyyymmdd>.bin.gz`, written by the
/// nightly import (backend/static-import/import.sh).
class SupabaseJourneysRepository implements IJourneysRepository {
  SupabaseJourneysRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Timetable?> timetable(NetworkInfo info, DateTime day) async {
    // gzip comes from dart:io: the planner is for the phone apps.
    if (kIsWeb) throw const NotSupportedFailure();
    final date = '${day.year}${'${day.month}'.padLeft(2, '0')}${'${day.day}'.padLeft(2, '0')}';
    // Kept in the app support folder: one file per day and version, the others are deleted.
    final folder = await getApplicationSupportDirectory();
    final file = File('${folder.path}/journeys_${info.version}_$date.bin.gz');
    if (!file.existsSync()) {
      final Uint8List bytes;
      try {
        bytes = await supabaseCall(
          () => _client.storage.from('network').download('journeys/v${info.version}/$date.bin.gz'),
        );
      } on ServerFailure catch (e) {
        // Storage answers 400 or 404 for a missing object: the import did not build this day.
        if (e.statusCode == 400 || e.statusCode == 404) return null;
        rethrow;
      }
      for (final old in folder.listSync().whereType<File>().where((f) => f.path.contains('/journeys_'))) {
        old.deleteSync();
      }
      await file.writeAsBytes(bytes);
    }
    return await compute(_decode, await file.readAsBytes());
  }

  static Timetable _decode(Uint8List gzipped) => Timetable.decode(Uint8List.fromList(gzip.decode(gzipped)));
}

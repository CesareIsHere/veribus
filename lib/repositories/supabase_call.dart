import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/core/utils/app_failure.dart';

/// Runs a Supabase request and turns its SDK errors into [AppFailure]s, so the rest of the app never sees Supabase types.
/// One mapping for every Supabase repository.
Future<T> supabaseCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on PostgrestException catch (e) {
    // program_limit_exceeded: raised by the server when a user is over a limit (`trip_follow_limit`).
    if (e.code == '54000') throw const LimitFailure();
    throw ServerFailure(statusCode: int.tryParse(e.code ?? '') ?? 500);
  } on StorageException catch (e) {
    throw ServerFailure(statusCode: int.tryParse(e.statusCode ?? '') ?? 500);
  } on SocketException {
    throw const NetworkFailure();
  } on ClientException {
    throw const NetworkFailure();
  }
}

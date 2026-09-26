import 'dart:convert';

import 'package:emiliano_cesare_flutter_template/models/user/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_repository.g.dart';

/// Persists the REST session (tokens + user) in the platform keychain.
class SessionRepository {
  SessionRepository([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<UserModel?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    return raw == null ? null : UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save({String? accessToken, String? refreshToken, UserModel? user}) async {
    if (accessToken != null) await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (user != null) await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() => _storage.deleteAll();
}

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) => SessionRepository();

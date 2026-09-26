import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/rest_auth_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/session/session_repository.dart';
import 'package:emiliano_cesare_flutter_template/services/api/api_client.dart';
import 'package:emiliano_cesare_flutter_template/services/api/endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers requests with [handler] instead of the network, counting calls per path.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final calls = <String, int>{};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.update(options.path, (c) => c + 1, ifAbsent: () => 1);
    await Future<void>.delayed(Duration.zero);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object> _session(String token) => {
  'accessToken': token,
  'refreshToken': 'refresh-$token',
  'user': {'id': '1', 'email': 'a@b.it'},
};

void main() {
  late SessionRepository session;
  late _FakeAdapter authServer;
  late RestAuthRepository repo;
  late Dio api;

  void setUpRepo(ResponseBody Function(RequestOptions) authHandler, ResponseBody Function(RequestOptions) apiHandler) {
    authServer = _FakeAdapter(authHandler);
    repo = RestAuthRepository(session, Dio()..httpClientAdapter = authServer, () => api);
    api = Dio()..httpClientAdapter = _FakeAdapter(apiHandler);
    api.interceptors.add(AuthInterceptor(api, () => repo));
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    session = SessionRepository();
  });

  test('refresh runs once for concurrent callers and stores the new session', () async {
    setUpRepo((_) => _json(_session('new')), (_) => _json({}));
    await session.save(accessToken: 'old', refreshToken: 'refresh-old');

    final tokens = await Future.wait([repo.refreshAccessToken(), repo.refreshAccessToken()]);

    expect(tokens, ['new', 'new']);
    expect(authServer.calls[Endpoints.authRefresh], 1);
    expect(await session.readRefreshToken(), 'refresh-new');
  });

  test('rejected refresh token signs out', () async {
    setUpRepo((_) => _json({'message': 'expired'}, 401), (_) => _json({}));
    await session.save(accessToken: 'old', refreshToken: 'refresh-old');

    expect(await repo.refreshAccessToken(), isNull);
    expect(await session.readAccessToken(), isNull);
  });

  test('network error during refresh keeps the session', () async {
    setUpRepo((_) => throw const SocketException('offline'), (_) => _json({}));
    await session.save(accessToken: 'old', refreshToken: 'refresh-old');

    expect(await repo.refreshAccessToken(), isNull);
    expect(await session.readAccessToken(), 'old');
  });

  test('interceptor adds the token, refreshes on 401 and retries once', () async {
    setUpRepo(
      (_) => _json(_session('new')),
      (o) => o.headers['Authorization'] == 'Bearer new' ? _json({'ok': true}) : _json({}, 401),
    );
    await session.save(accessToken: 'old', refreshToken: 'refresh-old');

    final res = await api.get<Map<String, dynamic>>(Endpoints.me);

    expect(res.data, {'ok': true});
    expect(authServer.calls[Endpoints.authRefresh], 1);
  });
}

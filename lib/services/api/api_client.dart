import 'package:dio/dio.dart';
import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/logger.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/auth_repository_provider.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/i_auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

part 'api_client.g.dart';

/// Shared HTTP client for your REST API: bearer token, refresh on 401,
/// logging, Sentry breadcrumbs.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.addAll([
    // Read lazily: the auth repository may itself use this client.
    AuthInterceptor(dio, () => ref.read(authRepositoryProvider)),
    TalkerDioLogger(
      talker: talker,
      settings: TalkerDioLoggerSettings(enabled: !AppConfig.isProd, hiddenHeaders: const {'authorization'}),
    ),
  ]);
  if (AppConfig.sentryDsn.isNotEmpty) dio.addSentry();
  ref.onDispose(dio.close);
  return dio;
}

/// Bare client for auth endpoints (login, refresh...): no token interceptor,
/// and bodies are never logged because they carry passwords and tokens.
Dio createAuthClient() => Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
  ..interceptors.add(
    TalkerDioLogger(
      talker: talker,
      settings: const TalkerDioLoggerSettings(printRequestData: false, printResponseData: false, printErrorData: false),
    ),
  );

/// Adds `Authorization: Bearer <token>`; on 401 refreshes once and retries.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._dio, this._auth);

  final Dio _dio;
  final IAuthRepository Function() _auth;
  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _auth().accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true) return handler.next(err);

    final token = await _auth().refreshAccessToken();
    if (token == null) return handler.next(err);

    options
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_retriedKey] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

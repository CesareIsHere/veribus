import 'package:dio/dio.dart';

/// Every error that reaches the UI is converted to one of these.
/// The user-facing text lives in `extensions/app_failure_extensions.dart`.
sealed class AppFailure implements Exception {
  const AppFailure();

  factory AppFailure.from(Object error) => switch (error) {
    final AppFailure failure => failure,
    final DioException e => _fromDio(e),
    _ => UnknownFailure(error),
  };

  static AppFailure _fromDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return const UnauthorizedFailure();
    if (status != null) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      return ServerFailure(statusCode: status, serverMessage: message);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const NetworkFailure(),
      _ => UnknownFailure(e),
    };
  }

  /// Failures worth sending to Sentry (the rest are expected user errors).
  bool get isUnexpected => switch (this) {
    UnknownFailure() => true,
    ServerFailure(:final statusCode) => statusCode >= 500,
    _ => false,
  };
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();
}

final class ServerFailure extends AppFailure {
  const ServerFailure({required this.statusCode, this.serverMessage});
  final int statusCode;
  final String? serverMessage;
}

final class NotSupportedFailure extends AppFailure {
  const NotSupportedFailure();
}

final class AuthFailure extends AppFailure {
  const AuthFailure(this.code);
  final AuthErrorCode code;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.error]);
  final Object? error;

  @override
  String toString() => 'UnknownFailure($error)';
}

enum AuthErrorCode {
  invalidCredentials,
  emailInUse,
  weakPassword,
  tooManyRequests,
  requiresRecentLogin,
  cancelled,

  /// Signed up (or signed in) before opening the confirmation link.
  emailNotConfirmed,
}

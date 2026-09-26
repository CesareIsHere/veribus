import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/logger.dart';
import 'package:emiliano_cesare_flutter_template/models/user/user_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/i_auth_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/session/session_repository.dart';
import 'package:emiliano_cesare_flutter_template/services/api/endpoints.dart';
import 'package:emiliano_cesare_flutter_template/services/social_sign_in.dart'; // feature:social_login
import 'package:flutter/foundation.dart';

/// JWT auth against your REST API. Contract: docs/BACKEND_API.md
class RestAuthRepository implements IAuthRepository {
  RestAuthRepository(this._session, this._authDio, this._api);

  final SessionRepository _session;

  /// Bare client for login/refresh (see `createAuthClient`): it must not go
  /// through the auth interceptor.
  final Dio _authDio;

  /// Authenticated client (token + refresh interceptor) for `/me` calls.
  /// A getter because that client itself depends on this repository.
  final Dio Function() _api;

  final _controller = StreamController<UserModel?>.broadcast();
  Future<String?>? _refreshing;

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield await _session.readUser();
    yield* _controller.stream;
  }

  @override
  Future<String?> accessToken() => _session.readAccessToken();

  @override
  Future<String?> refreshAccessToken() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final refreshToken = await _session.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final res = await _authDio.post<Map<String, dynamic>>(
        Endpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      await _saveSession(res.data!);
      return await _session.readAccessToken();
    } on DioException catch (e, s) {
      talker.handle(e, s, 'Token refresh failed');
      // Only a rejected refresh token ends the session: offline or 5xx keep
      // the user signed in so a later request can refresh again.
      if (e.response?.statusCode case 400 || 401 || 403) await signOut();
      return null;
    }
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    final res = await _authDio.post<Map<String, dynamic>>(
      Endpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    await _saveSession(res.data!);
  }

  @override
  Future<void> signUpWithEmail({required String email, required String password, String? displayName}) async {
    final res = await _authDio.post<Map<String, dynamic>>(
      Endpoints.authRegister,
      data: {'email': email, 'password': password, 'displayName': ?displayName},
    );
    await _saveSession(res.data!);
  }

  @override
  Future<void> signInWithGoogle() async {
    // feature:social_login:start
    final (:idToken, accessToken: _) = await SocialSignIn.google();
    await _socialLogin({'provider': 'google', 'token': idToken});
    // feature:social_login:end
  }

  @override
  Future<void> signInWithApple() async {
    // feature:social_login:start
    final apple = await SocialSignIn.apple();
    await _socialLogin({
      'provider': 'apple',
      'token': apple.identityToken,
      'nonce': apple.rawNonce,
      'displayName': ?apple.displayName,
    });
    // feature:social_login:end
  }

  // feature:social_login:start
  Future<void> _socialLogin(Map<String, dynamic> body) async {
    final res = await _authDio.post<Map<String, dynamic>>(Endpoints.authSocial, data: body);
    await _saveSession(res.data!);
  }
  // feature:social_login:end

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _authDio.post<void>(Endpoints.authForgotPassword, data: {'email': email});

  @override
  Future<void> confirmPasswordReset({required String token, required String newPassword}) =>
      _authDio.post<void>(Endpoints.authResetPassword, data: {'token': token, 'password': newPassword});

  @override
  Future<void> updateProfile({String? displayName, Uint8List? avatar}) async {
    Response<Map<String, dynamic>>? res;
    if (displayName != null) {
      res = await _api().patch<Map<String, dynamic>>(Endpoints.me, data: {'displayName': displayName});
    }
    if (avatar != null) {
      final form = FormData.fromMap({'file': MultipartFile.fromBytes(avatar, filename: 'avatar.jpg')});
      res = await _api().post<Map<String, dynamic>>(Endpoints.meAvatar, data: form);
    }
    if (res?.data case final data?) {
      final user = UserModel.fromJson(data);
      await _session.save(user: user);
      _controller.add(user);
    }
  }

  @override
  Future<void> registerPushToken(String token) =>
      _api().post<void>(Endpoints.devices, data: {'token': token, 'platform': defaultTargetPlatform.name});

  @override
  Future<void> deleteAccount() async {
    await _api().delete<void>(Endpoints.me);
    await signOut();
  }

  @override
  Future<void> signOut() async {
    await _session.clear();
    _controller.add(null);
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final user = data['user'] == null ? null : UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _session.save(
      accessToken: data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
      user: user,
    );
    if (user != null) _controller.add(user);
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/utils/app_failure.dart';

/// Native Google / Apple sign-in, shared by every backend.
/// The backend then exchanges the returned token for its own session.
abstract final class SocialSignIn {
  static Future<void>? _googleInit;

  /// Native Google sign-in. Not available on web: web uses the backend
  /// OAuth flow (Firebase popup, Supabase redirect) or Google's rendered button.
  ///
  /// `accessToken` is null unless the basic scopes are already granted (no
  /// extra consent screen). Supabase needs it when the ID token has `at_hash` (iOS).
  static Future<({String idToken, String? accessToken})> google() async {
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize(
      serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
    ));
    if (!google.supportsAuthenticate()) throw const NotSupportedFailure();
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const UnknownFailure('Google returned no idToken');
      final authorization = await account.authorizationClient.authorizationForScopes(const ['email', 'profile']);
      return (idToken: idToken, accessToken: authorization?.accessToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const AuthFailure(AuthErrorCode.cancelled);
      rethrow;
    }
  }

  /// Native Sign in with Apple (iOS/macOS). `rawNonce` must be sent along
  /// with the identity token so the backend can verify it.
  static Future<({String identityToken, String rawNonce, String? displayName})> apple() async {
    if (!await SignInWithApple.isAvailable()) throw const NotSupportedFailure();
    final rawNonce = _nonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final token = credential.identityToken;
      if (token == null) throw const UnknownFailure('Apple returned no identityToken');
      final name = [credential.givenName, credential.familyName].nonNulls.join(' ');
      return (identityToken: token, rawNonce: rawNonce, displayName: name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const AuthFailure(AuthErrorCode.cancelled);
      rethrow;
    }
  }

  static String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

import 'dart:typed_data';

import 'package:veribus/models/user/user_model.dart';

/// Auth contract. One implementation per backend (see `AppConfig.backend`):
/// `MockAuthRepository`, `RestAuthRepository`, `FirebaseAuthRepository`, `SupabaseAuthRepository`.
///
/// Implementations throw `AppFailure`s (or raw SDK errors, mapped later).
abstract interface class IAuthRepository {
  /// Emits the current user (or null) immediately, then on every change.
  Stream<UserModel?> authStateChanges();

  /// Bearer token for API calls, null when signed out.
  Future<String?> accessToken();

  /// Forces a new access token. Returns null (and signs out) when the
  /// session can't be refreshed.
  Future<String?> refreshAccessToken();

  Future<void> signInWithEmail({required String email, required String password});

  Future<void> signUpWithEmail({required String email, required String password, String? displayName});

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> sendPasswordResetEmail(String email);

  /// [token] comes from the reset link (`/reset-password?token=...`).
  Future<void> confirmPasswordReset({required String token, required String newPassword});

  Future<void> updateProfile({String? displayName, Uint8List? avatar});

  /// Links a push token (FCM) to the signed-in user, with the language the notices are written in. Again with a new
  /// [locale], it only updates that. The token is taken back by [signOut], and a token has one user at a time.
  Future<void> registerPushToken(String token, {required String locale});

  Future<void> deleteAccount();

  Future<void> signOut();
}

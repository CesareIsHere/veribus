import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/core/utils/logger.dart';
import 'package:veribus/models/user/user_model.dart';
import 'package:veribus/repositories/auth/i_auth_repository.dart';
import 'package:veribus/services/social_sign_in.dart'; // feature:social_login

/// Supabase Auth (+ Storage `avatars` bucket for avatars, `push_tokens` table).
/// Tables, RLS policies and `delete_account()` live in supabase/migrations.
class SupabaseAuthRepository implements IAuthRepository {
  SupabaseAuthRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// The push token registered in this session, taken back at sign-out.
  String? _pushToken;

  GoTrueClient get _auth => _client.auth;

  /// OAuth return address: the current site on web, an App Link on mobile.
  static String? get _redirectUrl =>
      kIsWeb ? Uri.base.origin : (AppConfig.authRedirectUrl.isEmpty ? null : AppConfig.authRedirectUrl);

  @override
  Stream<UserModel?> authStateChanges() => _auth.onAuthStateChange
      .map((state) => _toModel(state.session?.user))
      .distinct()
      // A failed background refresh (e.g. offline) must not look like a sign-out.
      .handleError((Object e, StackTrace s) => talker.handle(e, s, 'Supabase auth'));

  @override
  Future<String?> accessToken() async => _auth.currentSession?.accessToken;

  @override
  Future<String?> refreshAccessToken() async {
    try {
      return (await _auth.refreshSession()).session?.accessToken;
    } on AuthApiException {
      // Refresh token revoked or expired. Network errors are rethrown: they keep the session.
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) =>
      _guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<void> signUpWithEmail({required String email, required String password, String? displayName}) =>
      _guard(() async {
        final res = await _auth.signUp(email: email, password: password, data: {'display_name': ?displayName});
        // "Confirm email" is on in the dashboard: no session until the link is opened.
        if (res.session == null) throw const AuthFailure(AuthErrorCode.emailNotConfirmed);
      });

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    // feature:social_login:start
    if (kIsWeb) {
      await _auth.signInWithOAuth(OAuthProvider.google, redirectTo: _redirectUrl);
      return;
    }
    final google = await SocialSignIn.google();
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: google.idToken,
      accessToken: google.accessToken,
    );
    // feature:social_login:end
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    // feature:social_login:start
    final native =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
    if (!native) {
      await _auth.signInWithOAuth(OAuthProvider.apple, redirectTo: _redirectUrl);
      return;
    }
    final apple = await SocialSignIn.apple();
    await _auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: apple.identityToken, nonce: apple.rawNonce);
    // Apple sends the name only on the first sign-in.
    if (apple.displayName != null && _auth.currentUser?.userMetadata?['display_name'] == null) {
      await _auth.updateUser(UserAttributes(data: {'display_name': apple.displayName}));
    }
    // feature:social_login:end
  });

  /// The reset email must link to `/reset-password?token={{ .TokenHash }}` (see README).
  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() => _auth.resetPasswordForEmail(email));

  /// Runs on a throwaway client: verifying the token signs in, and doing that on
  /// the app's client would redirect away from the reset page mid-flow.
  @override
  Future<void> confirmPasswordReset({required String token, required String newPassword}) => _guard(() async {
    final recovery = SupabaseClient(
      AppConfig.supabaseUrl,
      AppConfig.supabasePublishableKey,
      // Implicit flow: PKCE needs persistent storage, and a token hash doesn't use it.
      authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit),
    );
    try {
      await recovery.auth.verifyOTP(type: OtpType.recovery, tokenHash: token);
      await recovery.auth.updateUser(UserAttributes(password: newPassword));
      await recovery.auth.signOut();
    } finally {
      await recovery.dispose();
    }
  });

  @override
  Future<void> updateProfile({String? displayName, Uint8List? avatar}) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const UnauthorizedFailure();
    String? photoUrl;
    if (avatar != null) {
      final path = '${user.id}/avatar.jpg';
      final bucket = _client.storage.from('avatars');
      await bucket.uploadBinary(path, avatar, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
      // Same path on every upload: the nonce makes caches fetch the new image.
      photoUrl = bucket.getPublicUrl(path, cacheNonce: '${DateTime.now().millisecondsSinceEpoch}');
    }
    await _auth.updateUser(UserAttributes(data: {'display_name': ?displayName, 'avatar_url': ?photoUrl}));
  });

  /// One device, one user: the RPC takes the token away from whoever else was registered with it.
  @override
  Future<void> registerPushToken(String token, {required String locale}) async {
    if (_auth.currentUser == null) return;
    await _client.schema('api').rpc<void>('register_push_token', params: {'token': token, 'locale': locale});
    _pushToken = token;
  }

  /// Rows cascade from `auth.users`; the avatar is removed first (Storage
  /// objects can't be deleted from SQL).
  @override
  Future<void> deleteAccount() => _guard(() async {
    final uid = _auth.currentUser?.id;
    if (uid == null) return;
    await _client.storage.from('avatars').remove(['$uid/avatar.jpg']);
    await _client.rpc<void>('delete_account');
    await _auth.signOut();
  });

  @override
  Future<void> signOut() async {
    await _forgetPushToken();
    await _auth.signOut();
  }

  /// This device stops getting the notices of the user who leaves. Best effort: signing out must not fail for this.
  Future<void> _forgetPushToken() async {
    final token = _pushToken;
    final uid = _auth.currentUser?.id;
    _pushToken = null;
    if (token == null || uid == null) return;
    try {
      await _client.from('push_tokens').delete().eq('user_id', uid).eq('token', token);
    } on Exception catch (e, s) {
      talker.handle(e, s, 'Supabase push token');
    }
  }

  static UserModel? _toModel(User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      // `full_name` / `picture` come from Google and Apple OAuth.
      displayName: (meta['display_name'] ?? meta['full_name'] ?? meta['name']) as String?,
      photoUrl: (meta['avatar_url'] ?? meta['picture']) as String?,
      emailVerified: user.emailConfirmedAt != null,
    );
  }

  /// Maps Supabase Auth error codes to [AuthFailure]s.
  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthRetryableFetchException {
      throw const NetworkFailure();
    } on AuthException catch (e) {
      final code = switch (e.code) {
        'invalid_credentials' || 'user_not_found' || 'email_address_invalid' => AuthErrorCode.invalidCredentials,
        'email_exists' || 'user_already_exists' || 'identity_already_exists' => AuthErrorCode.emailInUse,
        'weak_password' => AuthErrorCode.weakPassword,
        'over_request_rate_limit' || 'over_email_send_rate_limit' => AuthErrorCode.tooManyRequests,
        'reauthentication_needed' => AuthErrorCode.requiresRecentLogin,
        'email_not_confirmed' => AuthErrorCode.emailNotConfirmed,
        _ => null,
      };
      if (code == null) rethrow;
      throw AuthFailure(code);
    }
  }
}

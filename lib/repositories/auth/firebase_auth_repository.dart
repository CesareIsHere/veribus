import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/models/user/user_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/i_auth_repository.dart';
import 'package:emiliano_cesare_flutter_template/services/social_sign_in.dart'; // feature:social_login
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth (+ Storage for avatars, Firestore for push tokens).
class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseStorage? storage, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? FirebaseStorage.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  @override
  Stream<UserModel?> authStateChanges() => _auth.userChanges().map(
    (u) => u == null
        ? null
        : UserModel(
            id: u.uid,
            email: u.email ?? '',
            displayName: u.displayName,
            photoUrl: u.photoURL,
            emailVerified: u.emailVerified,
          ),
  );

  @override
  Future<String?> accessToken() => _auth.currentUser?.getIdToken() ?? Future.value();

  @override
  Future<String?> refreshAccessToken() => _auth.currentUser?.getIdToken(true) ?? Future.value();

  @override
  Future<void> signInWithEmail({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> signUpWithEmail({required String email, required String password, String? displayName}) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        if (displayName != null) await cred.user?.updateDisplayName(displayName);
      });

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    // feature:social_login:start
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    final (:idToken, accessToken: _) = await SocialSignIn.google();
    await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    // feature:social_login:end
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    // feature:social_login:start
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    await (kIsWeb ? _auth.signInWithPopup(provider) : _auth.signInWithProvider(provider));
    // feature:social_login:end
  });

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> confirmPasswordReset({required String token, required String newPassword}) =>
      _guard(() => _auth.confirmPasswordReset(code: token, newPassword: newPassword));

  @override
  Future<void> updateProfile({String? displayName, Uint8List? avatar}) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const UnauthorizedFailure();
    if (displayName != null) await user.updateDisplayName(displayName);
    if (avatar != null) {
      final ref = _storage.ref('users/${user.uid}/avatar.jpg');
      await ref.putData(avatar, SettableMetadata(contentType: 'image/jpeg'));
      await user.updatePhotoURL(await ref.getDownloadURL());
    }
  });

  @override
  Future<void> registerPushToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.doc('users/$uid').set({
      'pushTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAccount() => _guard(() => _auth.currentUser?.delete() ?? Future.value());

  @override
  Future<void> signOut() => _auth.signOut();

  /// Maps Firebase error codes to [AuthFailure]s.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      final code = switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' => AuthErrorCode.invalidCredentials,
        'email-already-in-use' || 'credential-already-in-use' => AuthErrorCode.emailInUse,
        'weak-password' => AuthErrorCode.weakPassword,
        'too-many-requests' => AuthErrorCode.tooManyRequests,
        'requires-recent-login' => AuthErrorCode.requiresRecentLogin,
        'web-context-canceled' || 'popup-closed-by-user' || 'canceled' => AuthErrorCode.cancelled,
        _ => null,
      };
      if (code == null) rethrow;
      throw AuthFailure(code);
    }
  }
}

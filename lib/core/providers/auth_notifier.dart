import 'package:emiliano_cesare_flutter_template/models/user/user_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/auth_repository_provider.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/i_auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// Current user (null = signed out). Drives router redirects.
///
/// Actions just forward to the repository: the new user arrives through
/// `authStateChanges()`, so there is a single source of truth.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<UserModel?> build() => ref.watch(authRepositoryProvider).authStateChanges();

  IAuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) =>
      _repo.signInWithEmail(email: email, password: password);

  Future<void> signUp({required String email, required String password, String? displayName}) =>
      _repo.signUpWithEmail(email: email, password: password, displayName: displayName);

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> signInWithApple() => _repo.signInWithApple();

  Future<void> sendPasswordReset(String email) => _repo.sendPasswordResetEmail(email);

  Future<void> confirmPasswordReset({required String token, required String newPassword}) =>
      _repo.confirmPasswordReset(token: token, newPassword: newPassword);

  Future<void> updateProfile({String? displayName, Uint8List? avatar}) =>
      _repo.updateProfile(displayName: displayName, avatar: avatar);

  Future<void> deleteAccount() => _repo.deleteAccount();

  Future<void> signOut() => _repo.signOut();
}

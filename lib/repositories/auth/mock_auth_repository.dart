import 'dart:async';
import 'dart:typed_data';

import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/user/user_model.dart';
import 'package:veribus/repositories/auth/i_auth_repository.dart';

/// In-memory auth: any email works, password `wrongpass` fails.
/// Used for demos, UI work without a server, and tests.
class MockAuthRepository implements IAuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _user;

  void _emit(UserModel? user) => _controller.add(_user = user);

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<String?> accessToken() async => _user == null ? null : 'mock-token';

  @override
  Future<String?> refreshAccessToken() => accessToken();

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    await Future<void>.delayed(latency);
    if (password == 'wrongpass') throw const AuthFailure(AuthErrorCode.invalidCredentials);
    _emit(UserModel(id: 'mock-${email.hashCode}', email: email, displayName: email.split('@').first));
  }

  @override
  Future<void> signUpWithEmail({required String email, required String password, String? displayName}) async {
    await Future<void>.delayed(latency);
    _emit(UserModel(id: 'mock-${email.hashCode}', email: email, displayName: displayName));
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(latency);
    _emit(const UserModel(id: 'mock-google', email: 'google.user@example.com', displayName: 'Google User'));
  }

  @override
  Future<void> signInWithApple() async {
    await Future<void>.delayed(latency);
    _emit(const UserModel(id: 'mock-apple', email: 'apple.user@example.com', displayName: 'Apple User'));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) => Future<void>.delayed(latency);

  @override
  Future<void> confirmPasswordReset({required String token, required String newPassword}) =>
      Future<void>.delayed(latency);

  @override
  Future<void> updateProfile({String? displayName, Uint8List? avatar}) async {
    await Future<void>.delayed(latency);
    final user = _user;
    if (user == null) throw const UnauthorizedFailure();
    _emit(user.copyWith(displayName: displayName ?? user.displayName));
  }

  @override
  Future<void> registerPushToken(String token) async {}

  @override
  Future<void> deleteAccount() => signOut();

  @override
  Future<void> signOut() async => _emit(null);
}

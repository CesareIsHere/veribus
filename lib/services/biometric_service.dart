import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_service.g.dart';

/// Biometrics / device PIN via local_auth (not available on web).
class BiometricService {
  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isSupported() async => !kIsWeb && await _auth.isDeviceSupported();

  Future<bool> authenticate(String reason) => _auth.authenticate(localizedReason: reason);
}

@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) => BiometricService();

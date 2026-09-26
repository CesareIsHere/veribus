import 'package:emiliano_cesare_flutter_template/core/providers/shared_preferences_provider.dart';
import 'package:emiliano_cesare_flutter_template/services/biometric_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_lock_notifier.g.dart';

@riverpod
Future<bool> biometricSupported(Ref ref) => ref.watch(biometricServiceProvider).isSupported();

/// Whether the app asks for biometrics/device PIN when reopened. Persisted.
@Riverpod(keepAlive: true)
class BiometricLockNotifier extends _$BiometricLockNotifier {
  static const _key = 'biometric_lock';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  /// Enabling requires a successful authentication first.
  Future<void> setEnabled({required bool enabled, required String reason}) async {
    if (enabled && !await authenticate(reason)) return;
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
  }

  Future<bool> authenticate(String reason) => ref.read(biometricServiceProvider).authenticate(reason);
}

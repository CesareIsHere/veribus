import 'package:emiliano_cesare_flutter_template/core/providers/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_notifier.g.dart';

/// true once the user has completed (or skipped) the onboarding.
@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  static const _key = 'onboarding_done';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

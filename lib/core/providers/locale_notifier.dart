import 'package:emiliano_cesare_flutter_template/core/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_notifier.g.dart';

/// App language; null follows the device language. Persisted.
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'locale';

  @override
  Locale? build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return saved == null ? null : Locale(saved);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await (locale == null ? prefs.remove(_key) : prefs.setString(_key, locale.languageCode));
  }
}

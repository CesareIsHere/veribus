// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App language; null follows the device language. Persisted.

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// App language; null follows the device language. Persisted.
final class LocaleNotifierProvider extends $NotifierProvider<LocaleNotifier, Locale?> {
  /// App language; null follows the device language. Persisted.
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Locale?>(value));
  }
}

String _$localeNotifierHash() => r'2ed64d327d634ce2f4fda5408bbeb09036ecb758';

/// App language; null follows the device language. Persisted.

abstract class _$LocaleNotifier extends $Notifier<Locale?> {
  Locale? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale?, Locale?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<Locale?, Locale?>, Locale?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

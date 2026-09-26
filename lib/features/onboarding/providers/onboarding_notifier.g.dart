// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// true once the user has completed (or skipped) the onboarding.

@ProviderFor(OnboardingNotifier)
final onboardingProvider = OnboardingNotifierProvider._();

/// true once the user has completed (or skipped) the onboarding.
final class OnboardingNotifierProvider extends $NotifierProvider<OnboardingNotifier, bool> {
  /// true once the user has completed (or skipped) the onboarding.
  OnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingNotifierHash();

  @$internal
  @override
  OnboardingNotifier create() => OnboardingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$onboardingNotifierHash() => r'0ee34fcb049318b031b2b1539c9b68d0fe2ea306';

/// true once the user has completed (or skipped) the onboarding.

abstract class _$OnboardingNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

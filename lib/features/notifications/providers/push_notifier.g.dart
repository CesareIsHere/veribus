// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Starts push at launch, keeps this device's token linked to the signed-in user (with the language of the app),
/// and opens the page of a notice the user taps.

@ProviderFor(PushNotifier)
final pushProvider = PushNotifierProvider._();

/// Starts push at launch, keeps this device's token linked to the signed-in user (with the language of the app),
/// and opens the page of a notice the user taps.
final class PushNotifierProvider extends $NotifierProvider<PushNotifier, PushState> {
  /// Starts push at launch, keeps this device's token linked to the signed-in user (with the language of the app),
  /// and opens the page of a notice the user taps.
  PushNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotifierHash();

  @$internal
  @override
  PushNotifier create() => PushNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<PushState>(value));
  }
}

String _$pushNotifierHash() => r'd0695c827def6df1ce150f121f834760be55d988';

/// Starts push at launch, keeps this device's token linked to the signed-in user (with the language of the app),
/// and opens the page of a notice the user taps.

abstract class _$PushNotifier extends $Notifier<PushState> {
  PushState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PushState, PushState>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<PushState, PushState>, PushState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

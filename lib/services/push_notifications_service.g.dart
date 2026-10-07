// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notifications_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pushService)
final pushServiceProvider = PushServiceProvider._();

final class PushServiceProvider extends $FunctionalProvider<IPushService, IPushService, IPushService>
    with $Provider<IPushService> {
  PushServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushServiceHash();

  @$internal
  @override
  $ProviderElement<IPushService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  IPushService create(Ref ref) {
    return pushService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IPushService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<IPushService>(value));
  }
}

String _$pushServiceHash() => r'3bbedd978a61b92dd4372fc7062285854a7bce58';

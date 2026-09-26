// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notifications_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pushNotificationsService)
final pushNotificationsServiceProvider = PushNotificationsServiceProvider._();

final class PushNotificationsServiceProvider
    extends $FunctionalProvider<PushNotificationsService, PushNotificationsService, PushNotificationsService>
    with $Provider<PushNotificationsService> {
  PushNotificationsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationsServiceHash();

  @$internal
  @override
  $ProviderElement<PushNotificationsService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  PushNotificationsService create(Ref ref) {
    return pushNotificationsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushNotificationsService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<PushNotificationsService>(value));
  }
}

String _$pushNotificationsServiceHash() => r'72893f75140bf982575fbeb54f00081b497e0c25';

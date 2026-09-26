// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Push notifications, active while a user is signed in: registers the device
/// token with the backend and opens the tapped notification's page.

@ProviderFor(pushNotifications)
final pushNotificationsProvider = PushNotificationsProvider._();

/// Push notifications, active while a user is signed in: registers the device
/// token with the backend and opens the tapped notification's page.

final class PushNotificationsProvider extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Push notifications, active while a user is signed in: registers the device
  /// token with the backend and opens the tapped notification's page.
  PushNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationsHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return pushNotifications(ref);
  }
}

String _$pushNotificationsHash() => r'e00f2d4536f1bb295904003e47007aa0a100089b';

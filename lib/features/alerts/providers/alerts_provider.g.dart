// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alerts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alerts)
final alertsProvider = AlertsProvider._();

final class AlertsProvider
    extends $FunctionalProvider<AsyncValue<List<ServiceAlert>>, List<ServiceAlert>, FutureOr<List<ServiceAlert>>>
    with $FutureModifier<List<ServiceAlert>>, $FutureProvider<List<ServiceAlert>> {
  AlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertsHash();

  @$internal
  @override
  $FutureProviderElement<List<ServiceAlert>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServiceAlert>> create(Ref ref) {
    return alerts(ref);
  }
}

String _$alertsHash() => r'846efda8af38182fff6827cceb4a5a75ccd0cfc4';

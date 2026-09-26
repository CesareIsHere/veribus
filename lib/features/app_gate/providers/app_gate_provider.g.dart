// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_gate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appGate)
final appGateProvider = AppGateProvider._();

final class AppGateProvider
    extends $FunctionalProvider<AsyncValue<AppGateStatus>, AppGateStatus, FutureOr<AppGateStatus>>
    with $FutureModifier<AppGateStatus>, $FutureProvider<AppGateStatus> {
  AppGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appGateHash();

  @$internal
  @override
  $FutureProviderElement<AppGateStatus> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppGateStatus> create(Ref ref) {
    return appGate(ref);
  }
}

String _$appGateHash() => r'c9a68de10344915b7a352cd8949424cc9b7cacee';

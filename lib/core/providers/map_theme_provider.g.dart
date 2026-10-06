// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The map style parsed once per brightness: reading it is not free and the layer compares themes by identity.

@ProviderFor(mapTheme)
final mapThemeProvider = MapThemeFamily._();

/// The map style parsed once per brightness: reading it is not free and the layer compares themes by identity.

final class MapThemeProvider extends $FunctionalProvider<Theme, Theme, Theme> with $Provider<Theme> {
  /// The map style parsed once per brightness: reading it is not free and the layer compares themes by identity.
  MapThemeProvider._({required MapThemeFamily super.from, required Brightness super.argument})
    : super(
        retry: null,
        name: r'mapThemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapThemeHash();

  @override
  String toString() {
    return r'mapThemeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Theme> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Theme create(Ref ref) {
    final argument = this.argument as Brightness;
    return mapTheme(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Theme value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Theme>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is MapThemeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapThemeHash() => r'9b4f089300d1ebdec36b5962128abed64fc55741';

/// The map style parsed once per brightness: reading it is not free and the layer compares themes by identity.

final class MapThemeFamily extends $Family with $FunctionalFamilyOverride<Theme, Brightness> {
  MapThemeFamily._()
    : super(
        retry: null,
        name: r'mapThemeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The map style parsed once per brightness: reading it is not free and the layer compares themes by identity.

  MapThemeProvider call(Brightness brightness) => MapThemeProvider._(argument: brightness, from: this);

  @override
  String toString() => r'mapThemeProvider';
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One direction of a line with its vehicles, refreshed while the page is open (RF-31).

@ProviderFor(lineDetail)
final lineDetailProvider = LineDetailFamily._();

/// One direction of a line with its vehicles, refreshed while the page is open (RF-31).

final class LineDetailProvider extends $FunctionalProvider<AsyncValue<LineDetail?>, LineDetail?, FutureOr<LineDetail?>>
    with $FutureModifier<LineDetail?>, $FutureProvider<LineDetail?> {
  /// One direction of a line with its vehicles, refreshed while the page is open (RF-31).
  LineDetailProvider._({required LineDetailFamily super.from, required (String, int) super.argument})
    : super(
        retry: null,
        name: r'lineDetailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineDetailHash();

  @override
  String toString() {
    return r'lineDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<LineDetail?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<LineDetail?> create(Ref ref) {
    final argument = this.argument as (String, int);
    return lineDetail(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is LineDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lineDetailHash() => r'1bee9ee2aff623edbd90352c1427010dcc7b0e78';

/// One direction of a line with its vehicles, refreshed while the page is open (RF-31).

final class LineDetailFamily extends $Family with $FunctionalFamilyOverride<FutureOr<LineDetail?>, (String, int)> {
  LineDetailFamily._()
    : super(
        retry: null,
        name: r'lineDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One direction of a line with its vehicles, refreshed while the page is open (RF-31).

  LineDetailProvider call(String lineId, int directionId) =>
      LineDetailProvider._(argument: (lineId, directionId), from: this);

  @override
  String toString() => r'lineDetailProvider';
}

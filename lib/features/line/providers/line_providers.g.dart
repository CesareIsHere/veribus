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

/// How a slot went on past days of the same kind (weekdays / weekend). It changes once a day: no refresh.

@ProviderFor(tripHistory)
final tripHistoryProvider = TripHistoryFamily._();

/// How a slot went on past days of the same kind (weekdays / weekend). It changes once a day: no refresh.

final class TripHistoryProvider
    extends $FunctionalProvider<AsyncValue<List<TripDay>>, List<TripDay>, FutureOr<List<TripDay>>>
    with $FutureModifier<List<TripDay>>, $FutureProvider<List<TripDay>> {
  /// How a slot went on past days of the same kind (weekdays / weekend). It changes once a day: no refresh.
  TripHistoryProvider._({
    required TripHistoryFamily super.from,
    required (String, String, int, int, {bool weekend}) super.argument,
  }) : super(
         retry: null,
         name: r'tripHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripHistoryHash();

  @override
  String toString() {
    return r'tripHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TripDay>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TripDay>> create(Ref ref) {
    final argument = this.argument as (String, String, int, int, {bool weekend});
    return tripHistory(ref, argument.$1, argument.$2, argument.$3, argument.$4, weekend: argument.weekend);
  }

  @override
  bool operator ==(Object other) {
    return other is TripHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripHistoryHash() => r'868d86b0eda663d032008126df6b546ea7cc7b9f';

/// How a slot went on past days of the same kind (weekdays / weekend). It changes once a day: no refresh.

final class TripHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TripDay>>, (String, String, int, int, {bool weekend})> {
  TripHistoryFamily._()
    : super(
        retry: null,
        name: r'tripHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How a slot went on past days of the same kind (weekdays / weekend). It changes once a day: no refresh.

  TripHistoryProvider call(
    String stopId,
    String lineId,
    int directionId,
    int departureSeconds, {
    required bool weekend,
  }) => TripHistoryProvider._(argument: (stopId, lineId, directionId, departureSeconds, weekend: weekend), from: this);

  @override
  String toString() => r'tripHistoryProvider';
}

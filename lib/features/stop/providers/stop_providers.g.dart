// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Arrivals of one stop, refreshed every 15 s while the panel is open (RF-24).

@ProviderFor(stopArrivals)
final stopArrivalsProvider = StopArrivalsFamily._();

/// Arrivals of one stop, refreshed every 15 s while the panel is open (RF-24).

final class StopArrivalsProvider extends $FunctionalProvider<AsyncValue<Arrivals>, Arrivals, FutureOr<Arrivals>>
    with $FutureModifier<Arrivals>, $FutureProvider<Arrivals> {
  /// Arrivals of one stop, refreshed every 15 s while the panel is open (RF-24).
  StopArrivalsProvider._({required StopArrivalsFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'stopArrivalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stopArrivalsHash();

  @override
  String toString() {
    return r'stopArrivalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Arrivals> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Arrivals> create(Ref ref) {
    final argument = this.argument as String;
    return stopArrivals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StopArrivalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stopArrivalsHash() => r'77d4824a4c20026a142126b3e51d01b3355ec31e';

/// Arrivals of one stop, refreshed every 15 s while the panel is open (RF-24).

final class StopArrivalsFamily extends $Family with $FunctionalFamilyOverride<FutureOr<Arrivals>, String> {
  StopArrivalsFamily._()
    : super(
        retry: null,
        name: r'stopArrivalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Arrivals of one stop, refreshed every 15 s while the panel is open (RF-24).

  StopArrivalsProvider call(String stopId) => StopArrivalsProvider._(argument: stopId, from: this);

  @override
  String toString() => r'stopArrivalsProvider';
}

@ProviderFor(timetable)
final timetableProvider = TimetableFamily._();

final class TimetableProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TimetableDirection>>,
          List<TimetableDirection>,
          FutureOr<List<TimetableDirection>>
        >
    with $FutureModifier<List<TimetableDirection>>, $FutureProvider<List<TimetableDirection>> {
  TimetableProvider._({required TimetableFamily super.from, required (String, String, DateTime) super.argument})
    : super(
        retry: null,
        name: r'timetableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timetableHash();

  @override
  String toString() {
    return r'timetableProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TimetableDirection>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TimetableDirection>> create(Ref ref) {
    final argument = this.argument as (String, String, DateTime);
    return timetable(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is TimetableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timetableHash() => r'0d1db759ca1fece5ba3af64360543d2e5243ebfa';

final class TimetableFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TimetableDirection>>, (String, String, DateTime)> {
  TimetableFamily._()
    : super(
        retry: null,
        name: r'timetableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimetableProvider call(String stopId, String lineId, DateTime day) =>
      TimetableProvider._(argument: (stopId, lineId, day), from: this);

  @override
  String toString() => r'timetableProvider';
}

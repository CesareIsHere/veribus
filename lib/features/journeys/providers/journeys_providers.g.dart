// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journeys_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Home, saved only on the phone ("lat,lon"), like the favorites. Null until the user sets it.

@ProviderFor(HomePlace)
final homePlaceProvider = HomePlaceProvider._();

/// Home, saved only on the phone ("lat,lon"), like the favorites. Null until the user sets it.
final class HomePlaceProvider extends $NotifierProvider<HomePlace, LatLng?> {
  /// Home, saved only on the phone ("lat,lon"), like the favorites. Null until the user sets it.
  HomePlaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePlaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePlaceHash();

  @$internal
  @override
  HomePlace create() => HomePlace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LatLng? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LatLng?>(value));
  }
}

String _$homePlaceHash() => r'1aa10d1afce1b89dbb8c54316f3fbd1de2e6cf81';

/// Home, saved only on the phone ("lat,lon"), like the favorites. Null until the user sets it.

abstract class _$HomePlace extends $Notifier<LatLng?> {
  LatLng? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LatLng?, LatLng?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<LatLng?, LatLng?>, LatLng?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// The planner on the timetable of [date] (yyyymmdd), kept for the session. Null when the nightly import did not
/// build that day's timetable.

@ProviderFor(journeyPlanner)
final journeyPlannerProvider = JourneyPlannerFamily._();

/// The planner on the timetable of [date] (yyyymmdd), kept for the session. Null when the nightly import did not
/// build that day's timetable.

final class JourneyPlannerProvider
    extends $FunctionalProvider<AsyncValue<JourneyPlanner?>, JourneyPlanner?, FutureOr<JourneyPlanner?>>
    with $FutureModifier<JourneyPlanner?>, $FutureProvider<JourneyPlanner?> {
  /// The planner on the timetable of [date] (yyyymmdd), kept for the session. Null when the nightly import did not
  /// build that day's timetable.
  JourneyPlannerProvider._({required JourneyPlannerFamily super.from, required int super.argument})
    : super(
        retry: null,
        name: r'journeyPlannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeyPlannerHash();

  @override
  String toString() {
    return r'journeyPlannerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<JourneyPlanner?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<JourneyPlanner?> create(Ref ref) {
    final argument = this.argument as int;
    return journeyPlanner(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyPlannerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journeyPlannerHash() => r'e301991674e8be16e57bc35da7a3fe2258c7bb8e';

/// The planner on the timetable of [date] (yyyymmdd), kept for the session. Null when the nightly import did not
/// build that day's timetable.

final class JourneyPlannerFamily extends $Family with $FunctionalFamilyOverride<FutureOr<JourneyPlanner?>, int> {
  JourneyPlannerFamily._()
    : super(
        retry: null,
        name: r'journeyPlannerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The planner on the timetable of [date] (yyyymmdd), kept for the session. Null when the nightly import did not
  /// build that day's timetable.

  JourneyPlannerProvider call(int date) => JourneyPlannerProvider._(argument: date, from: this);

  @override
  String toString() => r'journeyPlannerProvider';
}

/// Recomputed every minute while the page is open: departures pass and the realtime changes. Null when the
/// timetable of today is not available.

@ProviderFor(plannedTrip)
final plannedTripProvider = PlannedTripFamily._();

/// Recomputed every minute while the page is open: departures pass and the realtime changes. Null when the
/// timetable of today is not available.

final class PlannedTripProvider
    extends $FunctionalProvider<AsyncValue<PlannedTrip?>, PlannedTrip?, FutureOr<PlannedTrip?>>
    with $FutureModifier<PlannedTrip?>, $FutureProvider<PlannedTrip?> {
  /// Recomputed every minute while the page is open: departures pass and the realtime changes. Null when the
  /// timetable of today is not available.
  PlannedTripProvider._({required PlannedTripFamily super.from, required (LatLng, LatLng) super.argument})
    : super(
        retry: null,
        name: r'plannedTripProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannedTripHash();

  @override
  String toString() {
    return r'plannedTripProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PlannedTrip?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlannedTrip?> create(Ref ref) {
    final argument = this.argument as (LatLng, LatLng);
    return plannedTrip(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PlannedTripProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannedTripHash() => r'461de9a7be0ce498383690c62737afb1d7d6d93e';

/// Recomputed every minute while the page is open: departures pass and the realtime changes. Null when the
/// timetable of today is not available.

final class PlannedTripFamily extends $Family with $FunctionalFamilyOverride<FutureOr<PlannedTrip?>, (LatLng, LatLng)> {
  PlannedTripFamily._()
    : super(
        retry: null,
        name: r'plannedTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recomputed every minute while the page is open: departures pass and the realtime changes. Null when the
  /// timetable of today is not available.

  PlannedTripProvider call(LatLng from, LatLng to) => PlannedTripProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'plannedTripProvider';
}

/// How often the change worked in the last 30 days of the same kind, from the history of both trips.

@ProviderFor(changeReliability)
final changeReliabilityProvider = ChangeReliabilityFamily._();

/// How often the change worked in the last 30 days of the same kind, from the history of both trips.

final class ChangeReliabilityProvider
    extends $FunctionalProvider<AsyncValue<ChangeRecord>, ChangeRecord, FutureOr<ChangeRecord>>
    with $FutureModifier<ChangeRecord>, $FutureProvider<ChangeRecord> {
  /// How often the change worked in the last 30 days of the same kind, from the history of both trips.
  ChangeReliabilityProvider._({required ChangeReliabilityFamily super.from, required ChangeSlots super.argument})
    : super(
        retry: null,
        name: r'changeReliabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeReliabilityHash();

  @override
  String toString() {
    return r'changeReliabilityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ChangeRecord> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChangeRecord> create(Ref ref) {
    final argument = this.argument as ChangeSlots;
    return changeReliability(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChangeReliabilityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$changeReliabilityHash() => r'8d70b4a730b56d7ed5be4cb1f784eed74bf78373';

/// How often the change worked in the last 30 days of the same kind, from the history of both trips.

final class ChangeReliabilityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ChangeRecord>, ChangeSlots> {
  ChangeReliabilityFamily._()
    : super(
        retry: null,
        name: r'changeReliabilityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How often the change worked in the last 30 days of the same kind, from the history of both trips.

  ChangeReliabilityProvider call(ChangeSlots c) => ChangeReliabilityProvider._(argument: c, from: this);

  @override
  String toString() => r'changeReliabilityProvider';
}

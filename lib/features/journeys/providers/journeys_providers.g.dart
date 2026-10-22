// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journeys_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Home.

@ProviderFor(HomePlace)
final homePlaceProvider = HomePlaceProvider._();

/// Home.
final class HomePlaceProvider extends $NotifierProvider<HomePlace, LatLng?> {
  /// Home.
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

String _$homePlaceHash() => r'2117842b1a0fa7b3034af1044a0a4343e526c365';

/// Home.

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

/// Work.

@ProviderFor(WorkPlace)
final workPlaceProvider = WorkPlaceProvider._();

/// Work.
final class WorkPlaceProvider extends $NotifierProvider<WorkPlace, LatLng?> {
  /// Work.
  WorkPlaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workPlaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workPlaceHash();

  @$internal
  @override
  WorkPlace create() => WorkPlace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LatLng? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LatLng?>(value));
  }
}

String _$workPlaceHash() => r'bb2fe63ef103e42f5577809f83a7d051ac2a2ed6';

/// Work.

abstract class _$WorkPlace extends $Notifier<LatLng?> {
  LatLng? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LatLng?, LatLng?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<LatLng?, LatLng?>, LatLng?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// The last places chosen as destination, newest first, saved only on the phone like home.

@ProviderFor(RecentPlaces)
final recentPlacesProvider = RecentPlacesProvider._();

/// The last places chosen as destination, newest first, saved only on the phone like home.
final class RecentPlacesProvider extends $NotifierProvider<RecentPlaces, List<Place>> {
  /// The last places chosen as destination, newest first, saved only on the phone like home.
  RecentPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentPlacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentPlacesHash();

  @$internal
  @override
  RecentPlaces create() => RecentPlaces();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Place> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<List<Place>>(value));
  }
}

String _$recentPlacesHash() => r'6b3068802499340474452aae9f033c0594e5ee33';

/// The last places chosen as destination, newest first, saved only on the phone like home.

abstract class _$RecentPlaces extends $Notifier<List<Place>> {
  List<Place> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Place>, List<Place>>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<List<Place>, List<Place>>, List<Place>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Addresses and places matching [query], from the place search service.

@ProviderFor(placeSearch)
final placeSearchProvider = PlaceSearchFamily._();

/// Addresses and places matching [query], from the place search service.

final class PlaceSearchProvider extends $FunctionalProvider<AsyncValue<List<Place>>, List<Place>, FutureOr<List<Place>>>
    with $FutureModifier<List<Place>>, $FutureProvider<List<Place>> {
  /// Addresses and places matching [query], from the place search service.
  PlaceSearchProvider._({required PlaceSearchFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'placeSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSearchHash();

  @override
  String toString() {
    return r'placeSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Place>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Place>> create(Ref ref) {
    final argument = this.argument as String;
    return placeSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaceSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$placeSearchHash() => r'2ac644a0cd830cb651c188e27ce6c9ccf8f0d824';

/// Addresses and places matching [query], from the place search service.

final class PlaceSearchFamily extends $Family with $FunctionalFamilyOverride<FutureOr<List<Place>>, String> {
  PlaceSearchFamily._()
    : super(
        retry: null,
        name: r'placeSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Addresses and places matching [query], from the place search service.

  PlaceSearchProvider call(String query) => PlaceSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'placeSearchProvider';
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

/// Leaving at [at], now when null: recomputed every minute while the page is open, because departures pass and the
/// realtime changes. Null when the timetable of that day is not available.

@ProviderFor(plannedTrip)
final plannedTripProvider = PlannedTripFamily._();

/// Leaving at [at], now when null: recomputed every minute while the page is open, because departures pass and the
/// realtime changes. Null when the timetable of that day is not available.

final class PlannedTripProvider
    extends $FunctionalProvider<AsyncValue<PlannedTrip?>, PlannedTrip?, FutureOr<PlannedTrip?>>
    with $FutureModifier<PlannedTrip?>, $FutureProvider<PlannedTrip?> {
  /// Leaving at [at], now when null: recomputed every minute while the page is open, because departures pass and the
  /// realtime changes. Null when the timetable of that day is not available.
  PlannedTripProvider._({
    required PlannedTripFamily super.from,
    required (LatLng, LatLng, DateTime?, JourneyFilter) super.argument,
  }) : super(
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
    final argument = this.argument as (LatLng, LatLng, DateTime?, JourneyFilter);
    return plannedTrip(ref, argument.$1, argument.$2, argument.$3, argument.$4);
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

String _$plannedTripHash() => r'e99fbf099fc8dc42d226de59f1166d2949903e05';

/// Leaving at [at], now when null: recomputed every minute while the page is open, because departures pass and the
/// realtime changes. Null when the timetable of that day is not available.

final class PlannedTripFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlannedTrip?>, (LatLng, LatLng, DateTime?, JourneyFilter)> {
  PlannedTripFamily._()
    : super(
        retry: null,
        name: r'plannedTripProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Leaving at [at], now when null: recomputed every minute while the page is open, because departures pass and the
  /// realtime changes. Null when the timetable of that day is not available.

  PlannedTripProvider call(LatLng from, LatLng to, DateTime? at, JourneyFilter filter) =>
      PlannedTripProvider._(argument: (from, to, at, filter), from: this);

  @override
  String toString() => r'plannedTripProvider';
}

/// The streets a line runs along in one direction (its main path), for the journey map. Asked once: it does not move.

@ProviderFor(lineShape)
final lineShapeProvider = LineShapeFamily._();

/// The streets a line runs along in one direction (its main path), for the journey map. Asked once: it does not move.

final class LineShapeProvider
    extends $FunctionalProvider<AsyncValue<List<LatLng>>, List<LatLng>, FutureOr<List<LatLng>>>
    with $FutureModifier<List<LatLng>>, $FutureProvider<List<LatLng>> {
  /// The streets a line runs along in one direction (its main path), for the journey map. Asked once: it does not move.
  LineShapeProvider._({required LineShapeFamily super.from, required (String, int) super.argument})
    : super(
        retry: null,
        name: r'lineShapeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineShapeHash();

  @override
  String toString() {
    return r'lineShapeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<LatLng>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LatLng>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return lineShape(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is LineShapeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lineShapeHash() => r'12889d0bcc23d2fd908e80e0f9a45099c6ec13a5';

/// The streets a line runs along in one direction (its main path), for the journey map. Asked once: it does not move.

final class LineShapeFamily extends $Family with $FunctionalFamilyOverride<FutureOr<List<LatLng>>, (String, int)> {
  LineShapeFamily._()
    : super(
        retry: null,
        name: r'lineShapeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The streets a line runs along in one direction (its main path), for the journey map. Asked once: it does not move.

  LineShapeProvider call(String lineId, int directionId) =>
      LineShapeProvider._(argument: (lineId, directionId), from: this);

  @override
  String toString() => r'lineShapeProvider';
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

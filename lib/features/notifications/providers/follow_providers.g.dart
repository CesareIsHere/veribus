// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The trips the user follows, with today's state, refreshed while a page that shows them is open.

@ProviderFor(FollowsNotifier)
final followsProvider = FollowsNotifierProvider._();

/// The trips the user follows, with today's state, refreshed while a page that shows them is open.
final class FollowsNotifierProvider extends $AsyncNotifierProvider<FollowsNotifier, List<TripFollow>> {
  /// The trips the user follows, with today's state, refreshed while a page that shows them is open.
  FollowsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsNotifierHash();

  @$internal
  @override
  FollowsNotifier create() => FollowsNotifier();
}

String _$followsNotifierHash() => r'e09f9931e8a018dfe202207c6322f103c93e73f9';

/// The trips the user follows, with today's state, refreshed while a page that shows them is open.

abstract class _$FollowsNotifier extends $AsyncNotifier<List<TripFollow>> {
  FutureOr<List<TripFollow>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TripFollow>>, List<TripFollow>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TripFollow>>, List<TripFollow>>,
              AsyncValue<List<TripFollow>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The follow of a trip, if the user follows it (the timetable marks these).

@ProviderFor(followOf)
final followOfProvider = FollowOfFamily._();

/// The follow of a trip, if the user follows it (the timetable marks these).

final class FollowOfProvider extends $FunctionalProvider<TripFollow?, TripFollow?, TripFollow?>
    with $Provider<TripFollow?> {
  /// The follow of a trip, if the user follows it (the timetable marks these).
  FollowOfProvider._({required FollowOfFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'followOfProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followOfHash();

  @override
  String toString() {
    return r'followOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TripFollow?> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TripFollow? create(Ref ref) {
    final argument = this.argument as String;
    return followOf(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripFollow? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TripFollow?>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is FollowOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followOfHash() => r'7bf862c559be69dafd1ef8c004039c546e63227f';

/// The follow of a trip, if the user follows it (the timetable marks these).

final class FollowOfFamily extends $Family with $FunctionalFamilyOverride<TripFollow?, String> {
  FollowOfFamily._()
    : super(
        retry: null,
        name: r'followOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The follow of a trip, if the user follows it (the timetable marks these).

  FollowOfProvider call(String key) => FollowOfProvider._(argument: key, from: this);

  @override
  String toString() => r'followOfProvider';
}

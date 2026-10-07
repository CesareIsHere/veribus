// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
/// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.

@ProviderFor(FollowsNotifier)
final followsProvider = FollowsNotifierFamily._();

/// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
/// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.
final class FollowsNotifierProvider extends $AsyncNotifierProvider<FollowsNotifier, List<TripFollow>> {
  /// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
  /// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.
  FollowsNotifierProvider._({required FollowsNotifierFamily super.from, required bool super.argument})
    : super(
        retry: null,
        name: r'followsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followsNotifierHash();

  @override
  String toString() {
    return r'followsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FollowsNotifier create() => FollowsNotifier();

  @override
  bool operator ==(Object other) {
    return other is FollowsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followsNotifierHash() => r'4fb1dc9ed9e2c9b4252835289e9dfd2b6f506965';

/// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
/// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.

final class FollowsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          FollowsNotifier,
          AsyncValue<List<TripFollow>>,
          List<TripFollow>,
          FutureOr<List<TripFollow>>,
          bool
        > {
  FollowsNotifierFamily._()
    : super(
        retry: null,
        name: r'followsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
  /// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.

  FollowsNotifierProvider call({bool live = false}) => FollowsNotifierProvider._(argument: live, from: this);

  @override
  String toString() => r'followsProvider';
}

/// The trips the user follows, with today's state. [live] keeps it fresh while the page that shows today's state is open;
/// the timetable and the form need only what is followed, not a poll of the server every 15 seconds.

abstract class _$FollowsNotifier extends $AsyncNotifier<List<TripFollow>> {
  late final _$args = ref.$arg as bool;
  bool get live => _$args;

  FutureOr<List<TripFollow>> build({bool live = false});
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
    return element.handleCreate(ref, () => build(live: _$args));
  }
}

/// The keys of the followed trips (`TripFollow.key`): what the timetable marks. Watch it with `select` to rebuild only
/// when one trip flips.

@ProviderFor(followKeys)
final followKeysProvider = FollowKeysProvider._();

/// The keys of the followed trips (`TripFollow.key`): what the timetable marks. Watch it with `select` to rebuild only
/// when one trip flips.

final class FollowKeysProvider extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The keys of the followed trips (`TripFollow.key`): what the timetable marks. Watch it with `select` to rebuild only
  /// when one trip flips.
  FollowKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followKeysHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return followKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Set<String>>(value));
  }
}

String _$followKeysHash() => r'47b16645aca2058abd5f04b93deb7b95c6cf023e';

/// The follow of a trip, if the user follows it (the form starts from it).

@ProviderFor(followOf)
final followOfProvider = FollowOfFamily._();

/// The follow of a trip, if the user follows it (the form starts from it).

final class FollowOfProvider extends $FunctionalProvider<TripFollow?, TripFollow?, TripFollow?>
    with $Provider<TripFollow?> {
  /// The follow of a trip, if the user follows it (the form starts from it).
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

String _$followOfHash() => r'5c29ee65888c14116157f9b0a26597d8f9a01756';

/// The follow of a trip, if the user follows it (the form starts from it).

final class FollowOfFamily extends $Family with $FunctionalFamilyOverride<TripFollow?, String> {
  FollowOfFamily._()
    : super(
        retry: null,
        name: r'followOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The follow of a trip, if the user follows it (the form starts from it).

  FollowOfProvider call(String key) => FollowOfProvider._(argument: key, from: this);

  @override
  String toString() => r'followOfProvider';
}

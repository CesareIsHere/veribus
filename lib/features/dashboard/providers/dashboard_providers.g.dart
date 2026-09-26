// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// First day of the month shown by the dashboard.

@ProviderFor(SelectedMonth)
final selectedMonthProvider = SelectedMonthProvider._();

/// First day of the month shown by the dashboard.
final class SelectedMonthProvider extends $NotifierProvider<SelectedMonth, DateTime> {
  /// First day of the month shown by the dashboard.
  SelectedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedMonthHash();

  @$internal
  @override
  SelectedMonth create() => SelectedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<DateTime>(value));
  }
}

String _$selectedMonthHash() => r'2c87b91f4bcf90fb2e5833d0449ea061213f0739';

/// First day of the month shown by the dashboard.

abstract class _$SelectedMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<DateTime, DateTime>, DateTime, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(monthSummary)
final monthSummaryProvider = MonthSummaryFamily._();

final class MonthSummaryProvider
    extends $FunctionalProvider<AsyncValue<MonthSummary>, MonthSummary, FutureOr<MonthSummary>>
    with $FutureModifier<MonthSummary>, $FutureProvider<MonthSummary> {
  MonthSummaryProvider._({required MonthSummaryFamily super.from, required DateTime super.argument})
    : super(
        retry: null,
        name: r'monthSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthSummaryHash();

  @override
  String toString() {
    return r'monthSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MonthSummary> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<MonthSummary> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthSummaryHash() => r'5d65270214750530a517a1cc6c29fcf1c9dcb0f4';

final class MonthSummaryFamily extends $Family with $FunctionalFamilyOverride<FutureOr<MonthSummary>, DateTime> {
  MonthSummaryFamily._()
    : super(
        retry: null,
        name: r'monthSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MonthSummaryProvider call(DateTime month) => MonthSummaryProvider._(argument: month, from: this);

  @override
  String toString() => r'monthSummaryProvider';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veribus/core/config.dart'; // feature:push
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/journey_options_sheet.dart';
import 'package:veribus/features/journeys/journey_page.dart';
import 'package:veribus/features/journeys/place_search_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Where the journeys page opens: from where, to where. Without a start it is the user's position; without a
/// destination, home.
class JourneysArgs {
  const JourneysArgs({this.from, this.to});

  final Place? from;
  final Place? to;
}

/// Journeys from where the user is (or any place) to home or any address or place, now or later. Each journey says in
/// one look how long it takes, with which lines and the state of its first bus in the words of the stop page; the last
/// journey of the night comes first when the service ends soon.
class JourneysPage extends ConsumerStatefulWidget {
  const JourneysPage({this.args, super.key});

  static const route = '/journeys';

  final JourneysArgs? args;

  @override
  ConsumerState<JourneysPage> createState() => _JourneysPageState();
}

class _JourneysPageState extends ConsumerState<JourneysPage> {
  /// Closer than this, the user is there: no journey to plan.
  static const _arrivedMeters = 300.0;

  /// Null is the user's position.
  late Place? _from = widget.args?.from;
  late Place? _to = widget.args?.to;

  /// Null leaves now.
  DateTime? _at;
  JourneyFilter _filter = allTransport;

  Place? _destination(Place? home) => _to ?? home;

  Future<void> _search(PlaceSearchField field, Place? to) async {
    final result = await context.push<PlaceSearchResult>(
      PlaceSearchPage.route,
      extra: PlaceSearchArgs(from: _from, to: to, field: field),
    );
    if (result != null && mounted) {
      setState(() {
        _from = result.from;
        _to = result.to;
      });
    }
  }

  Future<void> _options() async {
    final result = await showJourneyOptions(context, at: _at, filter: _filter);
    if (result != null && mounted) {
      setState(() {
        _at = result.at;
        _filter = result.filter;
      });
    }
  }

  /// Start and destination trade places; the user's position becomes a place like any other.
  void _swap(Place to, LatLng? position) {
    final from = _from ?? (position == null ? null : Place(name: context.l10n.journeysYourPosition, point: position));
    if (from == null) return;
    setState(() {
      _from = to;
      _to = from;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final homePoint = ref.watch(homePlaceProvider);
    final home = homePoint == null ? null : Place(name: l10n.journeysHomePlace, point: homePoint, type: PlaceType.home);
    final to = _destination(home);
    // The position, renewed only after 100 m: riding a bus must not replan at every GPS fix.
    final position = ref.watch(nearbyOriginProvider);
    final origin = _from == null ? position : AsyncData(_from!.point);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RouteHeader(
              from: _from,
              to: to,
              onFrom: () => unawaited(_search(PlaceSearchField.from, to)),
              onTo: () => unawaited(_search(PlaceSearchField.to, to)),
              onSwap: to == null || (_from == null && position.value == null) ? null : () => _swap(to, position.value),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.s),
              child: Wrap(
                spacing: Spacing.s,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.schedule),
                    label: Text(
                      _at == null
                          ? l10n.journeysNow
                          : l10n.journeysDepartAt(
                              MaterialLocalizations.of(context)
                                  .formatTimeOfDay(TimeOfDay.fromDateTime(_at!), alwaysUse24HourFormat: true),
                            ),
                    ),
                    onPressed: () => unawaited(_options()),
                  ),
                  ActionChip(
                    avatar: Badge(
                      isLabelVisible: _filter != allTransport,
                      smallSize: Spacing.s,
                      child: const Icon(Icons.tune),
                    ),
                    label: Text(l10n.journeysOptions),
                    onPressed: () => unawaited(_options()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (origin) {
                _ when to == null => MessageView(
                  icon: Icons.directions_outlined,
                  title: l10n.journeysWhereTo,
                  description: l10n.journeysNoHomeHint,
                  action: FilledButton.icon(
                    onPressed: () => unawaited(_search(PlaceSearchField.to, null)),
                    icon: const Icon(Icons.search),
                    label: Text(l10n.journeysSearchAddress),
                  ),
                ),
                AsyncValue(:final error?) => MessageView.error(
                  context,
                  error,
                  onRetry: () => ref.invalidate(positionProvider),
                ),
                AsyncValue(hasValue: false) => const Center(child: CircularProgressIndicator()),
                AsyncValue(value: null) => MessageView(
                  icon: Icons.location_disabled,
                  title: l10n.journeysNeedPosition,
                  action: FilledButton.tonal(
                    onPressed: () => ref.read(locationTrackerProvider).enable(),
                    child: Text(l10n.enableLocation),
                  ),
                ),
                AsyncValue(hasValue: true, :final value)
                    when value != null && const Distance()(value, to.point) < _arrivedMeters =>
                  MessageView(
                    icon: to.isHome ? Icons.home : Icons.where_to_vote_outlined,
                    title: to.isHome ? l10n.journeysAtHome : l10n.journeysAlreadyThere,
                  ),
                AsyncValue(hasValue: true, :final value) => _Journeys(
                  from: _from ?? Place(name: l10n.journeysYourPosition, point: value!),
                  to: to,
                  at: _at,
                  filter: _filter,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Where from and where to, in a card that opens the search, with the button that swaps them.
class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.from, required this.to, required this.onFrom, required this.onTo, this.onSwap});

  final Place? from;
  final Place? to;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(Spacing.xs, Spacing.xs, context.pageMargin - Spacing.xs, Spacing.s),
      child: Row(
        spacing: Spacing.xs,
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          Expanded(
            child: Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(Spacing.l + Spacing.xs + Spacing.xs),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  InkWell(
                    onTap: onFrom,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m),
                      child: Row(
                        spacing: Spacing.m,
                        children: [
                          Icon(Icons.trip_origin, size: Spacing.l, color: scheme.primary),
                          Expanded(
                            child: Text(
                              from?.name ?? l10n.journeysYourPosition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: Spacing.xxxl, color: scheme.outlineVariant),
                  InkWell(
                    onTap: onTo,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m),
                      child: Row(
                        spacing: Spacing.m,
                        children: [
                          Icon(
                            to?.isHome ?? false ? Icons.home : Icons.place,
                            size: Spacing.l + Spacing.xs,
                            color: scheme.error,
                          ),
                          Expanded(
                            child: Text(
                              to?.name ?? l10n.journeysWhereTo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(tooltip: l10n.journeysSwap, icon: const Icon(Icons.swap_vert), onPressed: onSwap),
        ],
      ),
    );
  }
}

class _Journeys extends ConsumerWidget {
  const _Journeys({required this.from, required this.to, required this.at, required this.filter});

  final Place from;
  final Place to;
  final DateTime? at;
  final JourneyFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = plannedTripProvider(from.point, to.point, at, filter);
    final trip = ref.watch(provider);
    final google = OutlinedButton.icon(
      onPressed: () => unawaited(openInGoogleMaps(from.point, to.point)),
      icon: const Icon(Icons.open_in_new),
      label: Text(l10n.journeysOpenGoogleMaps),
    );
    return switch (trip) {
      AsyncValue(hasValue: false, :final error?) => MessageView.error(
        context,
        error,
        onRetry: () => ref.invalidate(provider),
      ),
      AsyncValue(hasValue: false) => const Center(child: CircularProgressIndicator()),
      AsyncValue(hasValue: true, :final value) when value == null => MessageView(
        icon: Icons.event_busy,
        title: l10n.journeysUnavailable,
        description: l10n.journeysUnavailableHint,
        action: google,
      ),
      AsyncValue(hasValue: true, :final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: _List(trip: value!, from: from, to: to, filter: filter, google: google),
      ),
    };
  }
}

class _List extends ConsumerWidget {
  const _List({required this.trip, required this.from, required this.to, required this.filter, required this.google});

  final PlannedTrip trip;
  final Place from;
  final Place to;

  /// What the search left out: the journey followed is planned again with the same limits.
  final JourneyFilter filter;
  final Widget google;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final (:planner, :journeys, :last) = trip;
    void open(PlannedJourney journey) => unawaited(
      context.push(
        JourneyPage.route,
        extra: JourneyArgs(planner: planner, journey: journey, from: from, to: to, filter: filter),
      ),
    );
    return ListView(
      padding: context.pagePadding(top: Spacing.s),
      children: [
        if (last != null) ...[
          _LastJourney(planner: planner, journey: last, onTap: () => open(last)),
          const SizedBox(height: Spacing.m),
        ],
        if (journeys.isEmpty)
          MessageView(icon: Icons.nights_stay_outlined, title: l10n.journeysNone, description: l10n.journeysNoneHint)
        else
          for (final journey in journeys) ...[
            JourneyCard(planner: planner, journey: journey, noRealtime: noRealtime, onTap: () => open(journey)),
            const SizedBox(height: Spacing.m),
          ],
        const SizedBox(height: Spacing.s),
        Center(child: google),
        const SizedBox(height: Spacing.xl),
        Text(l10n.journeysNote, style: context.textTheme.bodySmall),
      ],
    );
  }
}

/// The service ends soon: when to leave at the latest, told first so that nobody misses it, with the reminder.
class _LastJourney extends StatelessWidget {
  const _LastJourney({required this.planner, required this.journey, required this.onTap});

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final ride = journey.rides.firstOrNull;
    final follow = ride == null || !Features.push ? null : followRouteOf(planner, ride); // feature:push
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.tertiaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.m,
            children: [
              CircleAvatar(
                backgroundColor: scheme.tertiary,
                foregroundColor: scheme.onTertiary,
                child: const Icon(Icons.nightlight),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.xs,
                  children: [
                    Text(
                      l10n.journeysLast(journeyClock(planner, journey.journey.depart)),
                      style: context.textTheme.titleMedium?.copyWith(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.journeysLastHint,
                      style: context.textTheme.bodyMedium?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                    // feature:push:start
                    // Notified before the last bus passes, through the followed trips.
                    if (follow != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.s),
                        child: FilledButton.icon(
                          onPressed: () => context.push(follow),
                          icon: const Icon(Icons.notifications_outlined),
                          label: Text(l10n.journeysRemind),
                        ),
                      ),
                    // feature:push:end
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The same trip in Google Maps, for what Veribus cannot plan (more than two changes, the trains).
Future<void> openInGoogleMaps(LatLng from, LatLng to) => launchUrl(
  Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': '${from.latitude},${from.longitude}',
    'destination': '${to.latitude},${to.longitude}',
    'travelmode': 'transit',
  }),
  mode: LaunchMode.externalApplication,
);

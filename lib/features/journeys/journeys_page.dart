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
import 'package:veribus/features/journeys/home_place_page.dart';
import 'package:veribus/features/journeys/journey_page.dart';
import 'package:veribus/features/journeys/place_search_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Journeys from where the user is to home (the default, the problem the page was made for) or to any address or
/// place, now. Each journey says the state of its first bus in the words of the stop page; the last journey of the
/// night comes first when the service ends soon.
class JourneysPage extends ConsumerWidget {
  const JourneysPage({super.key});

  static const route = '/journeys';

  /// Closer than this, the user is there: no journey to plan.
  static const _arrivedMeters = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final home = ref.watch(homePlaceProvider);
    final chosen = ref.watch(journeyDestinationProvider);
    final to = chosen ?? (home == null ? null : Place(name: l10n.journeysHomePlace, point: home, isHome: true));
    // The position, renewed only after 100 m: riding a bus must not replan at every GPS fix.
    final origin = ref.watch(nearbyOriginProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journeysTitle),
        actions: [
          if (to != null && to.isHome)
            IconButton(
              tooltip: l10n.journeysChangeHome,
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: () => context.push(HomePlacePage.route),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, Spacing.s),
            child: _Destination(to: to),
          ),
          Expanded(
            child: switch (origin) {
              _ when to == null => MessageView(
                icon: Icons.home_outlined,
                title: l10n.journeysNoHome,
                description: l10n.journeysNoHomeHint,
                action: FilledButton.icon(
                  onPressed: () => context.push(HomePlacePage.route),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(l10n.journeysSetHome),
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
              AsyncValue(hasValue: true, :final value) => _Journeys(from: value!, to: to),
            },
          ),
        ],
      ),
    );
  }
}

/// Where the journeys go: home or the chosen place; a tap searches another one.
class _Destination extends ConsumerWidget {
  const _Destination({required this.to});

  final Place? to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final to = this.to;
    Future<void> choose() async {
      final place = await context.push<Place>(PlaceSearchPage.route);
      if (place != null) ref.read(journeyDestinationProvider.notifier).set(place);
    }

    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => unawaited(choose()),
        leading: Icon(
          to == null
              ? Icons.search
              : to.isHome
              ? Icons.home_outlined
              : Icons.place_outlined,
        ),
        title: Text(to?.name ?? l10n.journeysWhereTo),
        subtitle: to == null || to.detail.isEmpty
            ? null
            : Text(to.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: to == null
            ? null
            : Text(
                l10n.journeysChangeDestination,
                style: context.textTheme.labelLarge?.copyWith(color: context.colors.primary),
              ),
      ),
    );
  }
}

class _Journeys extends ConsumerWidget {
  const _Journeys({required this.from, required this.to});

  final LatLng from;
  final Place to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trip = ref.watch(plannedTripProvider(from, to.point));
    final google = OutlinedButton.icon(
      onPressed: () => unawaited(openInGoogleMaps(from, to.point)),
      icon: const Icon(Icons.open_in_new),
      label: Text(l10n.journeysOpenGoogleMaps),
    );
    return switch (trip) {
      AsyncValue(hasValue: false, :final error?) => MessageView.error(
        context,
        error,
        onRetry: () => ref.invalidate(plannedTripProvider(from, to.point)),
      ),
      AsyncValue(hasValue: false) => const Center(child: CircularProgressIndicator()),
      AsyncValue(hasValue: true, :final value) when value == null => MessageView(
        icon: Icons.event_busy,
        title: l10n.journeysUnavailable,
        description: l10n.journeysUnavailableHint,
        action: google,
      ),
      AsyncValue(hasValue: true, :final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(plannedTripProvider(from, to.point).future),
        child: _List(trip: value!, from: from, to: to, google: google),
      ),
    };
  }
}

class _List extends ConsumerWidget {
  const _List({required this.trip, required this.from, required this.to, required this.google});

  final PlannedTrip trip;
  final LatLng from;
  final Place to;
  final Widget google;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final (:planner, :journeys, :last) = trip;
    void open(PlannedJourney journey) => unawaited(
      context.push(
        JourneyPage.route,
        extra: JourneyArgs(planner: planner, journey: journey, from: from, to: to),
      ),
    );
    return ListView(
      padding: context.pagePadding(),
      children: [
        if (last != null) ...[
          _LastJourney(planner: planner, journey: last, onTap: () => open(last)),
          const SizedBox(height: Spacing.l),
        ],
        if (journeys.isEmpty)
          MessageView(icon: Icons.nights_stay_outlined, title: l10n.journeysNone, description: l10n.journeysNoneHint)
        else
          for (final journey in journeys) ...[
            JourneyCard(planner: planner, journey: journey, noRealtime: noRealtime, onTap: () => open(journey)),
            const SizedBox(height: Spacing.l),
          ],
        const SizedBox(height: Spacing.s),
        Center(child: google),
        const SizedBox(height: Spacing.xl),
        Text(l10n.journeysNote, style: context.textTheme.bodySmall),
      ],
    );
  }
}

/// The service ends soon: when to leave at the latest. Told first, so that nobody misses it.
class _LastJourney extends StatelessWidget {
  const _LastJourney({required this.planner, required this.journey, required this.onTap});

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      color: context.colors.tertiaryContainer,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.schedule, color: context.colors.onTertiaryContainer),
        title: Text(
          l10n.journeysLast(journeyClock(planner, journey.journey.depart)),
          style: context.textTheme.titleSmall?.copyWith(color: context.colors.onTertiaryContainer),
        ),
        subtitle: Text(
          l10n.journeysLastHint,
          style: context.textTheme.bodySmall?.copyWith(color: context.colors.onTertiaryContainer),
        ),
        trailing: switch (journey.rides.firstOrNull) {
          // feature:push:start
          // Notified before the last bus passes, through the followed trips.
          final ride? when Features.push && followRouteOf(planner, ride) != null => IconButton(
            tooltip: l10n.followTrip,
            onPressed: () => context.push(followRouteOf(planner, ride)!),
            icon: Icon(Icons.notifications_outlined, color: context.colors.onTertiaryContainer),
          ),
          // feature:push:end
          _ => Icon(Icons.chevron_right, color: context.colors.onTertiaryContainer),
        },
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

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
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/styles/app_spacing.dart';

/// "Go home": from where the user is to the home saved on the phone, now. Each journey says the state of its first
/// bus in the words of the stop page; the last journey of the night comes first when the service ends soon.
class JourneysPage extends ConsumerWidget {
  const JourneysPage({super.key});

  static const route = '/journeys';

  /// Closer than this, the user is home: no journey to plan.
  static const _homeMeters = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final home = ref.watch(homePlaceProvider);
    // The position, renewed only after 100 m: riding a bus must not replan at every GPS fix.
    final origin = ref.watch(nearbyOriginProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journeysHome),
        actions: [
          if (home != null)
            IconButton(
              tooltip: l10n.journeysChangeHome,
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: () => context.push(HomePlacePage.route),
            ),
        ],
      ),
      body: switch (origin) {
        _ when home == null => MessageView(
          icon: Icons.home_outlined,
          title: l10n.journeysNoHome,
          description: l10n.journeysNoHomeHint,
          action: FilledButton.icon(
            onPressed: () => context.push(HomePlacePage.route),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(l10n.journeysSetHome),
          ),
        ),
        AsyncValue(:final error?) => MessageView.error(context, error, onRetry: () => ref.invalidate(positionProvider)),
        AsyncValue(hasValue: false) => const Center(child: CircularProgressIndicator()),
        AsyncValue(value: null) => MessageView(
          icon: Icons.location_disabled,
          title: l10n.journeysNeedPosition,
          action: FilledButton.tonal(
            onPressed: () => ref.read(locationTrackerProvider).enable(),
            child: Text(l10n.enableLocation),
          ),
        ),
        AsyncValue(hasValue: true, :final value) when value != null && const Distance()(value, home) < _homeMeters =>
          MessageView(icon: Icons.home, title: l10n.journeysAtHome),
        AsyncValue(hasValue: true, :final value) => _Journeys(from: value!, to: home),
      },
    );
  }
}

class _Journeys extends ConsumerWidget {
  const _Journeys({required this.from, required this.to});

  final LatLng from;
  final LatLng to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trip = ref.watch(plannedTripProvider(from, to));
    final google = OutlinedButton.icon(
      onPressed: () => unawaited(openInGoogleMaps(from, to)),
      icon: const Icon(Icons.open_in_new),
      label: Text(l10n.journeysOpenGoogleMaps),
    );
    return switch (trip) {
      AsyncValue(hasValue: false, :final error?) => MessageView.error(
        context,
        error,
        onRetry: () => ref.invalidate(plannedTripProvider(from, to)),
      ),
      AsyncValue(hasValue: false) => const Center(child: CircularProgressIndicator()),
      AsyncValue(hasValue: true, :final value) when value == null => MessageView(
        icon: Icons.event_busy,
        title: l10n.journeysUnavailable,
        description: l10n.journeysUnavailableHint,
        action: google,
      ),
      AsyncValue(hasValue: true, :final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(plannedTripProvider(from, to).future),
        child: _List(trip: value!, from: from, to: to, google: google),
      ),
    };
  }
}

class _List extends ConsumerWidget {
  const _List({required this.trip, required this.from, required this.to, required this.google});

  final PlannedTrip trip;
  final LatLng from;
  final LatLng to;
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

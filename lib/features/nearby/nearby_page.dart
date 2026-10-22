import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/widgets/stale_banner.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/core/widgets/vehicles_layer.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/journeys_page.dart';
import 'package:veribus/features/line/components/vehicle_route_sheet.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/features/search/search_page.dart';
import 'package:veribus/features/settings/components/settings_button.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Nearby stops on a map or in a list (RF-01..07).
class NearbyPage extends ConsumerWidget {
  const NearbyPage({super.key});

  static const route = '/nearby';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final map = ref.watch(nearbyMapViewProvider);
    final position = ref.watch(positionProvider);
    // RF-61 / SC-01 1a: without network data the map would stay blank.
    final networkError = ref.watch(networkProvider).error;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, Spacing.s),
              child: Column(
                spacing: Spacing.s,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The same search as the Search tab, without leaving the page.
                  SearchAnchor.bar(
                    barHintText: l10n.searchHint,
                    barLeading: const Icon(Icons.search),
                    barTrailing: const [SettingsButton()],
                    viewHintText: l10n.searchHint,
                    suggestionsBuilder: (context, controller) {
                      final network = ref.read(networkProvider).value;
                      if (network == null || controller.text.trim().isEmpty) return const <Widget>[];
                      final r = network.search(controller.text);
                      if (r.lines.isEmpty && r.stops.isEmpty) return [ListTile(title: Text(l10n.searchNoResults))];
                      final noRealtime = ref.read(networkInfoProvider).value?.noRealtime ?? const {};
                      return searchResults(
                        context,
                        network,
                        r,
                        noRealtime,
                        open: (route) {
                          controller.closeView('');
                          unawaited(context.push(route));
                        },
                      );
                    },
                  ),
                  Row(
                    spacing: Spacing.s,
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: true, icon: const Icon(Icons.map_outlined), label: Text(l10n.mapView)),
                            ButtonSegment(value: false, icon: const Icon(Icons.list), label: Text(l10n.listView)),
                          ],
                          selected: {map},
                          onSelectionChanged: (s) => ref.read(nearbyMapViewProvider.notifier).set(map: s.first),
                        ),
                      ),
                      // Which bus to take to get home, or anywhere else, from here (journey planner).
                      FilledButton.tonalIcon(
                        onPressed: () => context.push(JourneysPage.route),
                        icon: const Icon(Icons.directions_outlined),
                        label: Text(l10n.journeysTitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (position case AsyncData(value: null))
              ListTile(
                leading: const Icon(Icons.location_disabled),
                title: Text(l10n.locationDenied),
                trailing: TextButton(
                  // Asks again or opens the right settings page; the position comes back by itself afterwards.
                  onPressed: () => ref.read(locationTrackerProvider).enable(),
                  child: Text(l10n.enableLocation),
                ),
              ),
            Expanded(
              child: switch (position) {
                _ when networkError != null => MessageView.error(
                  context,
                  networkError,
                  onRetry: () => ref.invalidate(networkInfoProvider),
                ),
                AsyncValue(isLoading: true) => const Center(child: CircularProgressIndicator()),
                AsyncValue(:final value) when map => _NearbyMap(position: value),
                AsyncValue(value: null) => MessageView(icon: Icons.search, title: l10n.locationDeniedList),
                _ => const _NearbyList(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyMap extends ConsumerStatefulWidget {
  const _NearbyMap({required this.position});

  final LatLng? position;

  @override
  ConsumerState<_NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends ConsumerState<_NearbyMap> {
  final _controller = MapController();

  @override
  Widget build(BuildContext context) {
    final network = ref.watch(networkProvider).value;
    final arrivals = ref.watch(nearbyArrivalsProvider).value;
    // The GPS was off or denied when the map opened and is on now: go to the user once, then leave the camera alone.
    ref.listen(positionProvider.select((p) => p.value), (previous, next) {
      if (previous == null && next != null) _controller.move(next, 16);
    });
    return TransitMap(
      controller: _controller,
      center: widget.position ?? rome,
      children: [
        if (network != null) _StopsLayer(network),
        // The vehicles heading to the nearby stops, moving: the arrivals refresh every 15 s while the map is open.
        VehiclesLayer(
          vehiclesOfArrivals(arrivals?.byStop.values.expand((list) => list) ?? const [], network),
          onTap: (v) => unawaited(showVehicleRouteSheet(context, vehicle: v)),
        ),
      ],
    );
  }
}

/// Stops in view, only from street level (RF-05: the map stays smooth in the center of Rome).
class _StopsLayer extends StatelessWidget {
  const _StopsLayer(this.network);

  final Network network;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (camera.zoom < 15) {
      return Align(
        alignment: Alignment.topCenter,
        child: Card(
          child: Padding(padding: const EdgeInsets.all(Spacing.m), child: Text(context.l10n.zoomInForStops)),
        ),
      );
    }
    final bounds = camera.visibleBounds;
    return MarkerLayer(
      markers: [
        for (final s in network.stops)
          if (bounds.contains(s.position))
            StopMarker(point: s.position, label: s.name, onTap: () => context.push(StopPage.route(s.id))),
      ],
    );
  }
}

/// Stops within 500 m with the next arrival of each line (RF-03).
class _NearbyList extends ConsumerWidget {
  const _NearbyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stops = ref.watch(nearbyStopsProvider);
    final arrivals = ref.watch(nearbyArrivalsProvider).value;
    final network = ref.watch(networkProvider).value;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final favorites = ref.watch(favoritesProvider.select((f) => f.stops.toSet()));
    return switch (stops) {
      AsyncValue(:final value?) when value.isEmpty => MessageView(
        icon: Icons.near_me_disabled,
        title: l10n.noStopsNearby,
      ),
      AsyncValue(:final value?) => RefreshIndicator(
        onRefresh: () => ref.refresh(nearbyArrivalsProvider.future),
        child: ListView(
          padding: context.listPadding(),
          children: [
            StaleBanner(arrivals?.feed),
            // Favorite stops first when they are nearby, then by distance (the sort is stable).
            for (final (:stop, :meters) in [
              ...value,
            ]..sort((a, b) => (favorites.contains(b.stop.id) ? 1 : 0) - (favorites.contains(a.stop.id) ? 1 : 0)))
              _StopCard(
                stop: stop,
                meters: meters,
                favorite: favorites.contains(stop.id),
                next: arrivals == null ? null : firstPerLine(arrivals.byStop[stop.id] ?? const []),
                network: network,
                noRealtime: noRealtime,
              ),
            Padding(
              padding: EdgeInsets.all(context.pageMargin),
              child: Text(l10n.nearbyNote, style: context.textTheme.bodySmall),
            ),
          ],
        ),
      ),
      AsyncValue(:final error?) => MessageView.error(context, error, onRetry: () => ref.invalidate(positionProvider)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.meters,
    required this.favorite,
    required this.next,
    required this.network,
    required this.noRealtime,
  });

  final Stop stop;
  final double meters;
  final bool favorite;
  final List<Arrival>? next;
  final Network? network;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(StopPage.route(stop.id)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageMargin, vertical: Spacing.m),
        child: Column(
          spacing: Spacing.s,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: Spacing.xs,
              children: [
                if (favorite)
                  Icon(
                    Icons.star,
                    size: Spacing.l,
                    color: context.colors.primary,
                    semanticLabel: context.l10n.favorites,
                  ),
                Expanded(child: Text(stop.name, style: context.textTheme.titleSmall)),
                Text(context.l10n.meters(meters.round()), style: context.textTheme.bodySmall),
              ],
            ),
            if (next == null)
              const LinearProgressIndicator()
            else if (next!.isEmpty)
              Text(context.l10n.noArrivals, style: context.textTheme.bodySmall)
            else
              // The card leads to the stop, each of its buses to its line.
              for (final a in next!)
                InkWell(
                  onTap: () => context.push(LinePage.routeOf(a, stop.id)),
                  child: Row(
                    spacing: Spacing.s,
                    children: [
                      LineBadge(
                        network?.lines[a.lineId]?.name ?? a.lineId,
                        withoutRealtime: noRealtime.contains(a.lineId),
                      ),
                      Expanded(child: Text('→ ${a.headsign}', maxLines: 2)),
                      ArrivalTime(a, large: false),
                      StatusTag(a.status),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

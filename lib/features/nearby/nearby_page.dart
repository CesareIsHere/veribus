import 'dart:async';
import 'dart:math' as math;

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
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/journeys_page.dart';
import 'package:veribus/features/journeys/place_search_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/journeys/save_place_page.dart';
import 'package:veribus/features/line/components/vehicle_route_sheet.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/nearby/components/metro_station.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/features/settings/components/settings_button.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/metro_stations.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/styles/app_spacing.dart';
import 'package:veribus/styles/app_theme.dart';

/// Explore: the map with "Where to?" on top, home and work one tap away, and the arrivals of the stops around the user
/// in a sheet that rises over the map (RF-01..07). The planner is the first thing here: it is why most people open
/// the app.
class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key});

  static const route = '/nearby';

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  final _controller = MapController();

  /// The sheet rests low enough for the map to be the page, high enough for the nearest stop.
  static const _sheetRest = 0.34;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// "Where to?": the search, then the journeys for what it brought back.
  Future<void> _where() async {
    final result = await context.push<PlaceSearchResult>(PlaceSearchPage.route);
    if (result == null || !mounted) return;
    await context.push(
      JourneysPage.route,
      extra: JourneysArgs(from: result.from, to: result.to),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final position = ref.watch(positionProvider);
    // RF-61 / SC-01 1a: without network data the map would stay blank.
    final networkError = ref.watch(networkProvider).error;
    final scheme = context.colors;
    if (networkError != null) {
      return Scaffold(
        body: MessageView.error(context, networkError, onRetry: () => ref.invalidate(networkInfoProvider)),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: switch (position) {
              AsyncValue(isLoading: true) => const Center(child: CircularProgressIndicator()),
              AsyncValue(:final value) => _NearbyMap(controller: _controller, position: value),
            },
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spacing.s,
                children: [
                  Material(
                    color: scheme.surfaceContainerHigh,
                    shape: const StadiumBorder(),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => unawaited(_where()),
                      child: SizedBox(
                        height: Spacing.xxxl + Spacing.s,
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: Spacing.l),
                              child: Icon(Icons.search),
                            ),
                            Expanded(
                              child: Text(
                                l10n.journeysWhereTo,
                                style: context.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                            const SettingsButton(),
                            const SizedBox(width: Spacing.xs),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const _SavedPlaces(),
                ],
              ),
            ),
          ),
          Positioned(
            right: context.pageMargin,
            top: MediaQuery.paddingOf(context).top + Spacing.xxxl * 2 + Spacing.xxl,
            child: FloatingActionButton.small(
              tooltip: l10n.backToMyPosition,
              onPressed: position.value == null
                  ? () => ref.read(locationTrackerProvider).enable()
                  : () => _controller.move(position.value!, math.max(_controller.camera.zoom, 16)),
              child: Icon(position.value == null ? Icons.location_disabled : Icons.my_location),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: _sheetRest,
            minChildSize: 0.14,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.14, _sheetRest, 0.92],
            builder: (context, scroll) => _NearbySheet(controller: scroll),
          ),
        ],
      ),
    );
  }
}

/// Home and work: one tap to the journeys when saved, to the map to set them when not. Saved places show how long the
/// fastest journey takes from here.
class _SavedPlaces extends ConsumerWidget {
  const _SavedPlaces();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: Spacing.s,
        children: [
          _SavedChip(
            type: PlaceType.home,
            label: l10n.journeysHomePlace,
            icon: Icons.home_outlined,
            point: ref.watch(homePlaceProvider),
          ),
          _SavedChip(
            type: PlaceType.work,
            label: l10n.journeysWorkPlace,
            icon: Icons.work_outline,
            point: ref.watch(workPlaceProvider),
          ),
        ],
      ),
    );
  }
}

class _SavedChip extends ConsumerWidget {
  const _SavedChip({required this.type, required this.label, required this.icon, required this.point});

  final PlaceType type;
  final String label;
  final IconData icon;
  final LatLng? point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final place = point == null ? null : Place(name: label, point: point!, type: type);
    final origin = ref.watch(nearbyOriginProvider).value;
    // How long it takes from here: the fastest journey of the planner. Nothing while it loads or when there is none.
    final trip = place == null || origin == null
        ? null
        : ref.watch(plannedTripProvider(origin, place.point, null, allTransport)).value;
    final first = trip?.journeys.firstOrNull;
    final text = first == null ? null : journeyDuration(context.l10n, first.journey.arrive - first.journey.depart);
    return ActionChip(
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 1,
      side: BorderSide.none,
      avatar: Icon(place == null ? Icons.add : icon, color: scheme.primary),
      label: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label),
            if (text != null)
              TextSpan(
                text: '  $text',
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
      onPressed: () => place == null
          ? unawaited(context.push(SavePlacePage.route, extra: SavePlaceArgs(type: type)))
          : unawaited(context.push(JourneysPage.route, extra: JourneysArgs(to: place))),
    );
  }
}

class _NearbyMap extends ConsumerStatefulWidget {
  const _NearbyMap({required this.controller, required this.position});

  final MapController controller;
  final LatLng? position;

  @override
  ConsumerState<_NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends ConsumerState<_NearbyMap> {
  @override
  Widget build(BuildContext context) {
    final network = ref.watch(networkProvider).value;
    final arrivals = ref.watch(nearbyArrivalsProvider).value;
    // The GPS was off or denied when the map opened and is on now: go to the user once, then leave the camera alone.
    ref.listen(positionProvider.select((p) => p.value), (previous, next) {
      if (previous == null && next != null) widget.controller.move(next, 16);
    });
    return TransitMap(
      controller: widget.controller,
      center: widget.position ?? rome,
      locateButton: false,
      children: [
        if (network != null) _StopsLayer(network),
        const _MetroLayer(),
        // The vehicles heading to the nearby stops, moving: the arrivals refresh every 15 s while the map is open.
        VehiclesLayer(
          vehiclesOfArrivals(arrivals?.byStop.values.expand((list) => list) ?? const [], network),
          onTap: (v) => unawaited(showVehicleRouteSheet(context, vehicle: v)),
        ),
      ],
    );
  }
}

/// The metro stations in view, from a wider zoom than the stops: there are few of them and they are far apart.
class _MetroLayer extends ConsumerWidget {
  const _MetroLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(metroStationsNowProvider).value;
    final camera = MapCamera.of(context);
    if (stations == null || camera.zoom < 13) return const SizedBox.shrink();
    final bounds = camera.visibleBounds;
    return MarkerLayer(
      markers: [
        for (final s in stations)
          if (bounds.contains(s.point)) MetroMarker(station: s, onTap: () => unawaited(showMetroSheet(context, s))),
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
    if (camera.zoom < 15) return const SizedBox.shrink();
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

/// The stops within 500 m with the next arrival of each line (RF-03), in a sheet over the map.
class _NearbySheet extends ConsumerStatefulWidget {
  const _NearbySheet({required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<_NearbySheet> createState() => _NearbySheetState();
}

class _NearbySheetState extends ConsumerState<_NearbySheet> {
  /// Null shows every kind of vehicle.
  TransitKind? _kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final position = ref.watch(positionProvider);
    final stops = ref.watch(nearbyStopsProvider);
    final arrivals = ref.watch(nearbyArrivalsProvider).value;
    final network = ref.watch(networkProvider).value;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final favorites = ref.watch(favoritesProvider.select((f) => f.stops.toSet()));
    return Material(
      color: scheme.surface,
      elevation: 3,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: widget.controller,
        padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.xl),
        children: [
          Center(
            child: Container(
              width: Spacing.xxl,
              height: Spacing.xs,
              margin: const EdgeInsets.symmetric(vertical: Spacing.m),
              decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l10n.exploreNearYou,
                  style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (arrivals != null && arrivals.feed != FeedStatus.stale)
                Row(
                  spacing: Spacing.xs,
                  children: [
                    Icon(Icons.rss_feed, size: Spacing.l, color: context.appColors.success),
                    Text(
                      l10n.updatedAgo(DateTime.now().difference(arrivals.computedAt).inSeconds.clamp(0, 3600)),
                      style: context.textTheme.labelMedium?.copyWith(color: context.appColors.success),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Spacing.m),
          Wrap(
            spacing: Spacing.s,
            children: [
              for (final (kind, label) in [
                (null, l10n.exploreAll),
                (TransitKind.bus, l10n.exploreBus),
                (TransitKind.tram, l10n.exploreTram),
                (TransitKind.metro, l10n.exploreMetro),
              ])
                FilterChip(
                  label: Text(label),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          if (position case AsyncData(value: null))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_disabled),
              title: Text(l10n.locationDenied),
              trailing: TextButton(
                // Asks again or opens the right settings page; the position comes back by itself afterwards.
                onPressed: () => ref.read(locationTrackerProvider).enable(),
                child: Text(l10n.enableLocation),
              ),
            ),
          const SizedBox(height: Spacing.m),
          StaleBanner(arrivals?.feed),
          if (_kind == TransitKind.metro)
            ..._metroStations(context, ref.watch(nearbyOriginProvider).value, ref.watch(metroStationsNowProvider).value)
          else
            ...switch (stops) {
              AsyncValue(:final value?) when value.isEmpty => [
                SizedBox(
                  height: 240,
                  child: MessageView(
                    icon: position.value == null ? Icons.search : Icons.near_me_disabled,
                    title: position.value == null ? l10n.locationDeniedList : l10n.noStopsNearby,
                  ),
                ),
              ],
              AsyncValue(:final value?) => [
                // The provider puts the favorite stops that are nearby first, then the rest by distance.
                for (final (:stop, :meters) in value)
                  ..._card(context, stop, meters, favorites.contains(stop.id), arrivals, network, noRealtime),
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.s),
                  child: Text(l10n.nearbyNote, style: context.textTheme.bodySmall),
                ),
              ],
              AsyncValue(:final error?) => [
                SizedBox(
                  height: 240,
                  child: MessageView.error(context, error, onRetry: () => ref.invalidate(positionProvider)),
                ),
              ],
              _ => [
                const Padding(
                  padding: EdgeInsets.all(Spacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
        ],
      ),
    );
  }

  /// The metro stations around, nearest first: a card each with its lines and how often they pass.
  List<Widget> _metroStations(BuildContext context, LatLng? at, List<MetroStation>? stations) {
    const distance = Distance();
    final near = at == null || stations == null
        ? const <({MetroStation station, double meters})>[]
        : ([
            for (final s in stations)
              if (distance(at, s.point) case final m when m <= 2000) (station: s, meters: m),
          ]..sort((a, b) => a.meters.compareTo(b.meters))).take(6).toList();
    if (near.isEmpty) {
      return [
        SizedBox(
          height: 240,
          child: MessageView(icon: Icons.subway, title: context.l10n.metroNoneNearby),
        ),
      ];
    }
    return [
      for (final (:station, :meters) in near)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.m),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => unawaited(showMetroSheet(context, station)),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.m,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(context.l10n.meters(meters.round()), style: context.textTheme.labelLarge),
                      ],
                    ),
                    MetroLines(station),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _card(
    BuildContext context,
    Stop stop,
    double meters,
    bool favorite,
    Arrivals? arrivals,
    Network? network,
    Set<String> noRealtime,
  ) {
    final next = arrivals == null
        ? null
        : [
            for (final a in firstPerLine(arrivals.byStop[stop.id] ?? const []))
              if (_kind == null || TransitKind.ofLineOrBus(network?.lines[a.lineId]) == _kind) a,
          ];
    // With a kind chosen, the stops that have none of it are left out.
    if (_kind != null && next != null && next.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: Spacing.m),
        child: _StopCard(
          stop: stop,
          meters: meters,
          favorite: favorite,
          next: next,
          network: network,
          noRealtime: noRealtime,
        ),
      ),
    ];
  }
}

class _StopCard extends ConsumerWidget {
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

  /// Metres a minute on foot, the pace the planner uses.
  static const double _walkSpeed = 1.2 * 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colors;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(StopPage.route(stop.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.m, Spacing.s, Spacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stop.name, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          l10n.exploreWalk(math.max(1, (meters / _walkSpeed).ceil()), meters.round()),
                          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: favorite ? l10n.removeFavorite : l10n.addFavorite,
                    icon: Icon(favorite ? Icons.star : Icons.star_outline, color: favorite ? scheme.primary : null),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggleStop(stop.id),
                  ),
                ],
              ),
              if (next == null)
                const Padding(
                  padding: EdgeInsets.only(right: Spacing.l),
                  child: LinearProgressIndicator(),
                )
              else if (next!.isEmpty)
                Text(l10n.noArrivals, style: context.textTheme.bodyMedium)
              else
                // The card leads to the stop, each of its buses to its line.
                for (final a in next!)
                  InkWell(
                    onTap: () => context.push(LinePage.routeOf(a, stop.id)),
                    borderRadius: BorderRadius.circular(Spacing.m),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, Spacing.s, Spacing.m, Spacing.s),
                      child: Row(
                        spacing: Spacing.m,
                        children: [
                          LineBadge(
                            network?.lines[a.lineId]?.name ?? a.lineId,
                            kind: TransitKind.ofLineOrBus(network?.lines[a.lineId]),
                            withoutRealtime: noRealtime.contains(a.lineId),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.headsign,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodyLarge,
                                ),
                                StatusTag(a.status),
                              ],
                            ),
                          ),
                          ArrivalTime(a),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

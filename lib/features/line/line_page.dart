import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/utils/report_problem.dart';
import 'package:veribus/core/widgets/alert_card.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/providers/line_providers.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Line detail (RF-30..35): stops of a direction in order with the vehicles between them, or the map.
class LinePage extends ConsumerStatefulWidget {
  const LinePage({required this.lineId, super.key});

  static String route(String id) => '/line/${Uri.encodeComponent(id)}';

  final String lineId;

  @override
  ConsumerState<LinePage> createState() => _LinePageState();
}

class _LinePageState extends ConsumerState<LinePage> {
  int? _direction;
  bool _map = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final line = network?.lines[widget.lineId];
    final withoutRealtime = ref.watch(networkInfoProvider).value?.noRealtime.contains(widget.lineId) ?? false;
    final favorite = ref.watch(favoritesProvider.select((f) => f.lines.contains(widget.lineId)));

    if (network != null && (line == null || line.directions.isEmpty)) {
      return Scaffold(
        appBar: AppBar(),
        body: MessageView(icon: Icons.directions_bus_outlined, title: l10n.lineNotServed),
      );
    }
    final direction = _direction ?? line?.directions.last.id ?? 0;
    final detail = ref.watch(lineDetailProvider(widget.lineId, direction));

    return Scaffold(
      appBar: AppBar(
        // Opened from a link there is nothing to pop: go back to the tabs.
        leading: context.canPop() ? null : BackButton(onPressed: () => context.go('/')),
        title: Row(
          spacing: Spacing.m,
          children: [LineBadge(line?.name ?? widget.lineId, withoutRealtime: withoutRealtime)],
        ),
        actions: [
          IconButton(
            tooltip: favorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(favorite ? Icons.star : Icons.star_outline),
            onPressed: () => ref.read(favoritesProvider.notifier).toggleLine(widget.lineId),
          ),
          if (canReportProblem)
            IconButton(
              tooltip: l10n.reportProblem,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => reportProblem(ref, about: l10n.lineDetail(line?.name ?? widget.lineId)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (line != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pageMargin, vertical: Spacing.s),
              child: Column(
                spacing: Spacing.s,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (line.directions.length > 1)
                    SegmentedButton<int>(
                      segments: [
                        for (final d in line.directions)
                          ButtonSegment(
                            value: d.id,
                            label: Text('→ ${d.headsign}', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      selected: {direction},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _direction = s.first),
                    ),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, icon: const Icon(Icons.list), label: Text(l10n.listView)),
                      ButtonSegment(value: true, icon: const Icon(Icons.map_outlined), label: Text(l10n.mapView)),
                    ],
                    selected: {_map},
                    onSelectionChanged: (s) => setState(() => _map = s.first),
                  ),
                ],
              ),
            ),
          Expanded(
            child: switch (detail) {
              AsyncValue(:final value?) when network != null =>
                _map ? _mapView(value, network) : _listView(context, value, network, withoutRealtime),
              AsyncValue(hasValue: true) => MessageView(icon: Icons.directions_bus_outlined, title: l10n.lineNotServed),
              AsyncValue(:final error?) => MessageView.error(
                context,
                error,
                onRetry: () => ref.invalidate(lineDetailProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  Widget _listView(BuildContext context, LineDetail d, Network network, bool withoutRealtime) {
    final l10n = context.l10n;
    final byIndex = <int, List<VehicleInfo>>{};
    for (final v in d.vehicles) {
      if (v.index != null) byIndex.putIfAbsent(v.index!, () => []).add(v);
    }
    return ListView(
      padding: context.listPadding(),
      children: [
        for (final alert in d.alerts)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.pageMargin, vertical: Spacing.xs),
            child: AlertCard(alert),
          ),
        if (withoutRealtime)
          ListTile(leading: const Icon(Icons.schedule), title: Text(l10n.lineWithoutRealtime))
        else if (d.vehicles.isEmpty)
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: Text(l10n.noTripsInService),
            subtitle: d.nextDeparture == null
                ? null
                : Text(l10n.nextDeparture(DateFormat.Hm().format(d.nextDeparture!.toLocal()))),
          )
        else
          ListTile(leading: const Icon(Icons.directions_bus), title: Text(l10n.vehiclesInService(d.vehicles.length))),
        for (final (i, id) in d.stopIds.indexed) ...[
          // Vehicles heading to stop i are drawn just above it.
          for (final v in byIndex[i] ?? const <VehicleInfo>[])
            ListTile(
              dense: true,
              leading: const SizedBox(width: Spacing.xl, child: Icon(Icons.directions_bus, size: 20)),
              title: Text(l10n.vehicle(v.label ?? v.id)),
              subtitle: v.signal == null ? null : Text(ArrivalText.signal(l10n, v.signal!)),
            ),
          ListTile(
            leading: SizedBox(
              width: Spacing.xl,
              child: Icon(i == 0 || i == d.stopIds.length - 1 ? Icons.trip_origin : Icons.circle_outlined, size: 16),
            ),
            title: Text(network.stopById[id]?.name ?? id),
            trailing: i == 0 || i == d.stopIds.length - 1 ? Text(l10n.terminus) : null,
            onTap: () => context.push(StopPage.route(id)),
          ),
        ],
      ],
    );
  }

  Widget _mapView(LineDetail d, Network network) {
    final stops = [for (final id in d.stopIds) ?network.stopById[id]];
    final center = d.shape.isEmpty ? rome : d.shape[d.shape.length ~/ 2];
    return TransitMap(
      center: center,
      zoom: 13,
      children: [
        PolylineLayer(
          polylines: [Polyline(points: d.shape, strokeWidth: 4, color: context.colors.primary)],
        ),
        MarkerLayer(
          markers: [
            for (final s in stops)
              StopMarker(point: s.position, label: s.name, onTap: () => context.push(StopPage.route(s.id))),
            for (final v in d.vehicles) VehicleMarker(point: v.position, label: v.label ?? v.id),
          ],
        ),
      ],
    );
  }
}

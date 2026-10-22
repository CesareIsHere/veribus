import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/utils/report_problem.dart';
import 'package:veribus/core/widgets/alert_card.dart';
import 'package:veribus/core/widgets/stale_banner.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/providers/stop_providers.dart';
import 'package:veribus/features/stop/timetable_page.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Stop panel (RF-20..29): arrivals of every line in the next 60 minutes, with status and reason.
class StopPage extends ConsumerStatefulWidget {
  const StopPage({required this.stopId, super.key});

  static String route(String id) => '/stop/$id';

  final String stopId;

  @override
  ConsumerState<StopPage> createState() => _StopPageState();
}

class _StopPageState extends ConsumerState<StopPage> {
  /// Temporary filter on one line (RF-27), not saved.
  String? _line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final stop = network?.stopById[widget.stopId];
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final favorite = ref.watch(favoritesProvider.select((f) => f.stops.contains(widget.stopId)));
    final arrivals = ref.watch(stopArrivalsProvider(widget.stopId));

    if (network != null && stop == null) {
      return Scaffold(
        appBar: AppBar(),
        body: MessageView(icon: Icons.location_off_outlined, title: l10n.stopNotServed),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Opened from a link there is nothing to pop: go back to the tabs.
        leading: Navigator.canPop(context) ? null : BackButton(onPressed: () => context.go('/')),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stop?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(l10n.stopCode(widget.stopId), style: context.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: favorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(favorite ? Icons.star : Icons.star_outline),
            onPressed: () => ref.read(favoritesProvider.notifier).toggleStop(widget.stopId),
          ),
          if (canReportProblem)
            IconButton(
              tooltip: l10n.reportProblem,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => reportProblem(ref, about: '${l10n.stopCode(widget.stopId)} ${stop?.name ?? ''}'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(stopArrivalsProvider(widget.stopId).future),
        child: ListView(
          padding: context.listPadding(),
          children: [
            if (stop != null) _lineFilter(context, network!, stop, noRealtime),
            ...switch (arrivals) {
              AsyncValue(:final value?) => _arrivals(context, network, stop, value, noRealtime),
              AsyncValue(:final error?) => [
                SizedBox(
                  height: 320,
                  child: MessageView.error(context, error, onRetry: () => ref.invalidate(stopArrivalsProvider)),
                ),
              ],
              _ => [
                const Padding(
                  padding: EdgeInsets.all(Spacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  Widget _lineFilter(BuildContext context, Network network, Stop stop, Set<String> noRealtime) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: context.pageMargin, vertical: Spacing.s),
      child: Row(
        spacing: Spacing.s,
        children: [
          ChoiceChip(label: Text(context.l10n.allLines), selected: _line == null, onSelected: (_) => _pick(null)),
          for (final id in stop.lineIds)
            ChoiceChip(
              label: Text(network.lines[id]?.name ?? id),
              avatar: noRealtime.contains(id) ? const Icon(Icons.schedule, size: 16) : null,
              selected: _line == id,
              onSelected: (_) => _pick(id),
            ),
        ],
      ),
    );
  }

  void _pick(String? line) => setState(() => _line = line);

  List<Widget> _arrivals(BuildContext context, Network? network, Stop? stop, Arrivals data, Set<String> noRealtime) {
    final l10n = context.l10n;
    final list = [
      for (final a in data.byStop[widget.stopId] ?? const <Arrival>[])
        if (_line == null || a.lineId == _line) a,
    ];
    final line = _line ?? stop?.lineIds.firstOrNull;
    final seconds = DateTime.now().difference(data.computedAt).inSeconds.clamp(0, 3600);
    return [
      if (data.alertsAt(widget.stopId) case final alerts when alerts.isNotEmpty)
        AlertsTile(alerts, onTapLine: (id) => context.push(LinePage.route(id))),
      StaleBanner(data.feed),
      if (list.isEmpty)
        MessageView(icon: Icons.nights_stay_outlined, title: l10n.noArrivals)
      else
        for (final a in list)
          ArrivalTile(
            arrival: a,
            lineName: network?.lines[a.lineId]?.name ?? a.lineId,
            kind: TransitKind.ofLineOrBus(network?.lines[a.lineId]),
            lineWithoutRealtime: noRealtime.contains(a.lineId),
            onTap: () => context.push(LinePage.routeOf(a, widget.stopId)),
          ),
      const Divider(),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
        child: Wrap(
          spacing: Spacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(l10n.updatedAgo(seconds), style: context.textTheme.bodySmall),
            if (line != null)
              TextButton(
                onPressed: () => context.push(TimetablePage.route(widget.stopId, line)),
                child: Text(l10n.timetable),
              ),
            if (_line != null)
              TextButton(
                onPressed: () => context.push(LinePage.route(_line!)),
                child: Text(l10n.lineDetail(network?.lines[_line]?.name ?? _line!)),
              ),
          ],
        ),
      ),
    ];
  }
}

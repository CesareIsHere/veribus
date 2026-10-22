import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/section_header.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/settings/components/settings_button.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Lines: every line of the network by kind of vehicle, and one bar for lines and stops, searched on the phone while
/// typing (RF-10, RF-11).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  static const route = '/search';

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider);
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, Spacing.s),
              child: SearchBar(
                hintText: l10n.linesSearchHint,
                leading: const Icon(Icons.search),
                trailing: const [SettingsButton()],
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
            Expanded(
              child: switch (network) {
                AsyncValue(:final value?) => Builder(
                  builder: (context) {
                    if (_query.trim().isEmpty) return _AllLines(network: value, noRealtime: noRealtime);
                    final r = value.search(_query);
                    if (r.lines.isEmpty && r.stops.isEmpty) {
                      return MessageView(icon: Icons.search_off, title: l10n.searchNoResults);
                    }
                    return ListView(
                      padding: context.listPadding(),
                      children: searchResults(context, value, r, noRealtime, open: (route) => context.push(route)),
                    );
                  },
                ),
                AsyncValue(:final error?) => MessageView.error(
                  context,
                  error,
                  onRetry: () => ref.invalidate(networkInfoProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Every line of the network, bus then tram then night buses, each with where it goes.
class _AllLines extends StatelessWidget {
  const _AllLines({required this.network, required this.noRealtime});

  final Network network;
  final Set<String> noRealtime;

  /// "2" before "10" before "8BUS" before "n1": numbers by value, then by letters.
  static int _compare(Line a, Line b) {
    final (x, y) = (int.tryParse(a.name), int.tryParse(b.name));
    if (x != null && y != null) return x.compareTo(y);
    if (x != null) return -1;
    if (y != null) return 1;
    return a.name.compareTo(b.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = [
      (l10n.linesBus, TransitKind.bus),
      (l10n.linesTram, TransitKind.tram),
      (l10n.linesNight, TransitKind.night),
    ];
    final items = <Object>[
      for (final (title, kind) in groups) ...[
        ...() {
          final lines = network.lines.values.where((l) => TransitKind.ofLine(l) == kind).toList()..sort(_compare);
          return lines.isEmpty ? const <Object>[] : <Object>[title, ...lines];
        }(),
      ],
    ];
    return ListView.builder(
      padding: context.listPadding(),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        final String title => SectionHeader(title),
        final Line line => ListTile(
          leading: LineBadge(line.name, kind: TransitKind.ofLine(line), withoutRealtime: noRealtime.contains(line.id)),
          title: Text(line.ends, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: noRealtime.contains(line.id) ? Text(l10n.withoutRealtime) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(LinePage.route(line.id)),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

/// The tiles of a search: lines, then stops. Shared by this tab and the bar on Nearby, which closes its view in [open].
List<Widget> searchResults(
  BuildContext context,
  Network network,
  ({List<Line> lines, List<Stop> stops}) r,
  Set<String> noRealtime, {
  required void Function(String route) open,
}) {
  final l10n = context.l10n;
  return [
    if (r.lines.isNotEmpty) SectionHeader(l10n.lines),
    for (final line in r.lines)
      ListTile(
        leading: LineBadge(line.name, kind: TransitKind.ofLine(line), withoutRealtime: noRealtime.contains(line.id)),
        title: Text(line.ends),
        subtitle: noRealtime.contains(line.id) ? Text(l10n.withoutRealtime) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => open(LinePage.route(line.id)),
      ),
    if (r.stops.isNotEmpty) SectionHeader(l10n.stops),
    for (final stop in r.stops)
      ListTile(
        leading: SizedBox(
          width: Spacing.xxxl,
          child: Text(stop.id, style: context.textTheme.labelMedium),
        ),
        title: Text(stop.name),
        subtitle: Text(stop.lineIds.map((id) => network.lines[id]?.name ?? id).join(', ')),
        onTap: () => open(StopPage.route(stop.id)),
      ),
  ];
}

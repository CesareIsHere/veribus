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

/// One bar for lines and stops, searched on the phone while typing (RF-10, RF-11).
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
                hintText: l10n.searchHint,
                leading: const Icon(Icons.search),
                trailing: const [SettingsButton()],
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
            Expanded(
              child: switch (network) {
                AsyncValue(:final value?) => Builder(
                  builder: (context) {
                    if (_query.trim().isEmpty) {
                      return MessageView(icon: Icons.search, title: l10n.searchEmpty);
                    }
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

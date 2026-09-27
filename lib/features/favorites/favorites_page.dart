import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/section_header.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/favorites/providers/favorites_arrivals_provider.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/settings/settings_page.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Favorite stops with their next arrivals and lines with vehicles in service (RF-41). Info is reached from here.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  static const route = '/favorites';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorites = ref.watch(favoritesProvider);
    final network = ref.watch(networkProvider).value;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final arrivals = ref.watch(favoritesArrivalsProvider);
    final data = arrivals.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(SettingsPage.route),
          ),
        ],
      ),
      body: favorites.stops.isEmpty && favorites.lines.isEmpty
          ? MessageView(icon: Icons.star_outline, title: l10n.noFavorites, description: l10n.noFavoritesHint)
          : RefreshIndicator(
              onRefresh: () => ref.refresh(favoritesArrivalsProvider.future),
              child: ListView(
                padding: context.listPadding(),
                children: [
                  if (arrivals.hasError && data == null)
                    MessageView.error(
                      context,
                      arrivals.error!,
                      onRetry: () => ref.invalidate(favoritesArrivalsProvider),
                    ),
                  if (favorites.stops.isNotEmpty) SectionHeader(l10n.stops),
                  for (final id in favorites.stops)
                    if (network != null && network.stopById[id] == null)
                      _NotServed(
                        title: l10n.stopCode(id),
                        onRemove: () => ref.read(favoritesProvider.notifier).toggleStop(id),
                      )
                    else ...[
                      ListTile(
                        title: Text(network?.stopById[id]?.name ?? id, style: context.textTheme.titleSmall),
                        subtitle: Text(l10n.stopCode(id)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(StopPage.route(id)),
                      ),
                      if (data == null)
                        const LinearProgressIndicator()
                      else
                        for (final a in _firstPerLine(data.byStop[id] ?? const []).take(4))
                          ArrivalTile(
                            arrival: a,
                            lineName: network?.lines[a.lineId]?.name ?? a.lineId,
                            lineWithoutRealtime: noRealtime.contains(a.lineId),
                            onTap: () => context.push(StopPage.route(id)),
                          ),
                      const SizedBox(height: Spacing.s),
                    ],
                  if (favorites.lines.isNotEmpty) SectionHeader(l10n.lines),
                  for (final id in favorites.lines)
                    if (network != null && network.lines[id] == null)
                      _NotServed(title: id, onRemove: () => ref.read(favoritesProvider.notifier).toggleLine(id))
                    else
                      ListTile(
                        leading: LineBadge(network?.lines[id]?.name ?? id, withoutRealtime: noRealtime.contains(id)),
                        title: Text(network?.lines[id]?.ends ?? ''),
                        subtitle: Text(
                          noRealtime.contains(id)
                              ? l10n.withoutRealtime
                              : l10n.vehiclesInService(data?.vehiclesInService[id] ?? 0),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(LinePage.route(id)),
                      ),
                ],
              ),
            ),
    );
  }

  static List<Arrival> _firstPerLine(List<Arrival> arrivals) {
    final seen = <String>{};
    return [
      for (final a in arrivals)
        if (a.status != ArrivalStatus.canceled && seen.add('${a.lineId}/${a.directionId}')) a,
    ];
  }
}

/// A favorite that a new network version no longer has (SC-13b).
class _NotServed extends StatelessWidget {
  const _NotServed({required this.title, required this.onRemove});

  final String title;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(context.l10n.notServedAnymore),
    trailing: IconButton(tooltip: context.l10n.delete, icon: const Icon(Icons.delete_outline), onPressed: onRemove),
  );
}

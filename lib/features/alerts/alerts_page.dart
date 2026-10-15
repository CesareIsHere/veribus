import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/alert_card.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/alerts/providers/alerts_provider.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/settings/components/settings_button.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Every active alert, most severe first (RF-50), filtered by line.
class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  static const route = '/alerts';

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  /// Temporary filter on one line, not saved.
  String? _line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.alerts), actions: const [SettingsButton()]),
      body: switch (ref.watch(alertsProvider)) {
        AsyncValue(:final value?) when value.isEmpty => MessageView(
          icon: Icons.check_circle_outline,
          title: l10n.noAlerts,
        ),
        AsyncValue(:final value?) => _list(context, value),
        AsyncValue(:final error?) => MessageView.error(context, error, onRetry: () => ref.invalidate(alertsProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _list(BuildContext context, List<ServiceAlert> value) {
    // A line no alert names any more (they were refreshed) falls back to all.
    final line = value.any((a) => a.lineIds.contains(_line)) ? _line : null;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(alertsProvider.future),
      child: ListView(
        padding: context.listPadding(),
        children: [
          _lineFilter(context, value, line),
          for (final a in value)
            // Network-wide alerts concern every line.
            if (line == null || a.lineIds.isEmpty || a.lineIds.contains(line))
              Padding(
                padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.s),
                child: AlertCard(a, onTapLine: (id) => context.push(LinePage.route(id))),
              ),
        ],
      ),
    );
  }

  /// The lines named by the alerts, favorites first, then by name.
  Widget _lineFilter(BuildContext context, List<ServiceAlert> alerts, String? selected) {
    final network = ref.watch(networkProvider).value;
    final favorites = ref.watch(favoritesProvider).lines;
    String name(String id) => network?.lines[id]?.name ?? id;
    final lines = {for (final a in alerts) ...a.lineIds}.toList()
      ..sort((a, b) {
        final fav = (favorites.contains(b) ? 1 : 0) - (favorites.contains(a) ? 1 : 0);
        if (fav != 0) return fav;
        // Numbers in order (64 before 170), then the others (8BUS, n11) alphabetically.
        const other = 1 << 30;
        final byNumber = (int.tryParse(name(a)) ?? other).compareTo(int.tryParse(name(b)) ?? other);
        return byNumber != 0 ? byNumber : name(a).compareTo(name(b));
      });
    if (lines.isEmpty) return const SizedBox(height: Spacing.s);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: context.pageMargin, vertical: Spacing.s),
      child: Row(
        spacing: Spacing.s,
        children: [
          ChoiceChip(
            label: Text(context.l10n.allLines),
            selected: selected == null,
            onSelected: (_) => setState(() => _line = null),
          ),
          for (final id in lines)
            ChoiceChip(
              label: Text(name(id)),
              avatar: favorites.contains(id) ? const Icon(Icons.star, size: Spacing.l) : null,
              selected: selected == id,
              onSelected: (_) => setState(() => _line = id),
            ),
        ],
      ),
    );
  }
}

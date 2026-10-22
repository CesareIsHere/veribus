import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/widgets/dialogs/confirm_dialog.dart';
import 'package:veribus/core/widgets/section_header.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/components/trip_history_card.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/notifications/components/notifications_banner.dart';
import 'package:veribus/features/notifications/providers/follow_providers.dart';
import 'package:veribus/features/notifications/providers/push_notifier.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Create or edit the follow of one trip: which days, how long before the bus passes (up to three notices).
/// A full-screen dialog (close + Save), as every create/edit screen.
class FollowPage extends ConsumerStatefulWidget {
  const FollowPage({
    required this.stopId,
    required this.lineId,
    required this.directionId,
    required this.departureSeconds,
    this.weekday,
    super.key,
  });

  static const route = '/follow';

  static String routeFor({
    required String stopId,
    required String lineId,
    required int directionId,
    required int departureSeconds,
    int? weekday,
  }) => Uri(
    path: route,
    queryParameters: {
      'stop': stopId,
      'line': lineId,
      'dir': '$directionId',
      'dep': '$departureSeconds',
      'wd': ?weekday?.toString(),
    },
  ).toString();

  final String stopId;
  final String lineId;
  final int directionId;
  final int departureSeconds;

  /// The weekday (1 Monday .. 7 Sunday) of the timetable the time was tapped on: the trip surely runs that day.
  final int? weekday;

  @override
  ConsumerState<FollowPage> createState() => _FollowPageState();
}

class _FollowPageState extends ConsumerState<FollowPage> {
  /// What most people want: the commute, ten and five minutes before.
  static const _weekdays = {1, 2, 3, 4, 5};
  static const _defaultLeads = [10, 5];

  /// The commute (Mon–Fri), unless the time was picked on a weekend timetable: weekend service differs.
  Set<int> get _defaultDays => switch (widget.weekday) {
    final d? when d > 5 => {d},
    _ => _weekdays,
  };

  late final String _key = TripFollow.keyOf(widget.stopId, widget.lineId, widget.directionId, widget.departureSeconds);
  Set<int>? _days;
  List<int>? _leads;
  bool? _enabled;
  var _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final existing = ref.watch(followOfProvider(_key));
    final follows = ref.watch(followsProvider());
    // Existing follows arrive with the first read: the form starts from them, then from what the user changed.
    final days = _days ?? existing?.days ?? _defaultDays;
    final leads = _leads ?? existing?.leadMinutes ?? _defaultLeads;
    final enabled = _enabled ?? existing?.enabled ?? true;
    final line = network?.lines[widget.lineId];
    final valid = days.isNotEmpty && leads.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: l10n.close, icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text(existing == null ? l10n.followTrip : l10n.followedMarker),
        actions: [
          TextButton(
            onPressed: valid && !_saving && follows.hasValue ? () => unawaited(_save(days, leads, enabled)) : null,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: context.pagePadding(maxWidth: ContentWidth.form),
        children: [
          Card.outlined(
            margin: EdgeInsets.zero,
            child: ListTile(
              onTap: () => context.push(
                LinePage.route(
                  widget.lineId,
                  directionId: widget.directionId,
                  stopId: widget.stopId,
                  departureSeconds: widget.departureSeconds,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              leading: LineBadge(line?.name ?? widget.lineId, kind: TransitKind.ofLineOrBus(line)),
              title: Text('→ ${line?.headsignOf(widget.directionId) ?? ''}'),
              subtitle: Text(
                '${network?.stopById[widget.stopId]?.name ?? widget.stopId} · ${clockOf(widget.departureSeconds)}',
              ),
            ),
          ),
          // What to expect from this trip on the days chosen.
          TripHistoryCard(
            stopId: widget.stopId,
            lineId: widget.lineId,
            directionId: widget.directionId,
            departureSeconds: widget.departureSeconds,
            weekend: days.isNotEmpty && days.every((d) => d >= DateTime.saturday),
            margin: const EdgeInsets.only(top: Spacing.l),
            showTrip: false,
          ),
          const NotificationsBanner(),
          SectionHeader(
            l10n.followDays,
            padding: const EdgeInsets.only(top: Spacing.xl, bottom: Spacing.s),
          ),
          Wrap(
            spacing: Spacing.s,
            runSpacing: Spacing.s,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(weekdayName(d)),
                  selected: days.contains(d),
                  onSelected: (on) => setState(() => _days = on ? {...days, d} : ({...days}..remove(d))),
                ),
            ],
          ),
          SectionHeader(
            l10n.followLeads,
            padding: const EdgeInsets.only(top: Spacing.xl, bottom: Spacing.xs),
          ),
          Text(l10n.followLeadsHint(TripFollow.maxLeads), style: context.textTheme.bodySmall),
          const SizedBox(height: Spacing.s),
          Wrap(
            spacing: Spacing.s,
            runSpacing: Spacing.s,
            children: [
              for (final m in TripFollow.leadOptions)
                FilterChip(
                  label: Text(l10n.minutes(m)),
                  selected: leads.contains(m),
                  // The fourth is not offered: three are chosen already.
                  onSelected: !leads.contains(m) && leads.length >= TripFollow.maxLeads
                      ? null
                      : (on) =>
                            setState(() => _leads = TripFollow.sortedLeads([...leads.where((x) => x != m), if (on) m])),
                ),
            ],
          ),
          if (existing != null) ...[
            const SizedBox(height: Spacing.xl),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.followEnabled),
              value: enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: Spacing.l),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: context.colors.error),
                icon: const Icon(Icons.notifications_off_outlined),
                label: Text(l10n.followRemove),
                onPressed: () => unawaited(_remove(existing)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(Set<int> days, List<int> leads, bool enabled) async {
    setState(() => _saving = true);
    final l10n = context.l10n;
    final push = ref.read(pushProvider.notifier);
    final follows = ref.read(followsProvider().notifier);
    final saved = await ExceptionHandler.handle(context, () async {
      // The first follow is the moment to ask for the permission: the reason is clear.
      if (!ref.read(pushProvider).ready) await push.enable();
      await follows.save(
        TripFollow(
          stopId: widget.stopId,
          lineId: widget.lineId,
          directionId: widget.directionId,
          departureSeconds: widget.departureSeconds,
          days: days,
          leadMinutes: leads,
          enabled: enabled,
        ),
      );
    }, successMessage: l10n.followSaved);
    if (!mounted) return;
    if (saved) {
      context.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _remove(TripFollow existing) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.followRemoveTitle,
      message: l10n.followRemoveBody,
      confirmLabel: l10n.followRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final removed = await ExceptionHandler.handle(
      context,
      () => ref.read(followsProvider().notifier).remove(existing.id!),
    );
    if (removed && mounted) context.pop();
  }
}

/// "Mon" / "lun", in the app language (1 = Monday).
String weekdayName(int isoWeekday) => DateFormat.E().format(DateTime(2024, 1, isoWeekday)); // 2024-01-01 is a Monday

/// "Mon–Fri", "Every day", "Sat, Sun": the days of a follow in few words.
String daysSummary(AppLocalizations l10n, Set<int> days) {
  final sorted = days.toList()..sort();
  if (sorted.length == 7) return l10n.everyDay;
  if (sorted.length == 5 && sorted.first == 1 && sorted.last == 5) return l10n.weekdays;
  if (sorted.length == 2 && sorted.first == 6) return l10n.weekend;
  return sorted.map(weekdayName).join(', ');
}

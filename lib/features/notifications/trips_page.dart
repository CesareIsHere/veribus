import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/notifications/components/notifications_banner.dart';
import 'package:veribus/features/notifications/follow_page.dart';
import 'package:veribus/features/notifications/providers/follow_providers.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/styles/app_spacing.dart';

/// The trips the user follows: when, on which days, how long before they are notified, and how today's trip is doing.
class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  static const route = '/trips';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final follows = ref.watch(followsProvider(live: true));
    return Scaffold(
      appBar: AppBar(
        // Opened from a notice there is nothing to pop: go back to the tabs.
        leading: Navigator.canPop(context) ? null : BackButton(onPressed: () => context.go('/')),
        title: Text(l10n.followedTrips),
      ),
      body: switch (follows) {
        AsyncValue(:final value?) when value.isEmpty => ListView(
          padding: context.pagePadding(),
          children: [
            const NotificationsBanner(),
            MessageView(icon: Icons.notifications_none, title: l10n.noFollows, description: l10n.noFollowsHint),
          ],
        ),
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: () => ref.refresh(followsProvider(live: true).future),
          child: ListView(
            padding: context.listPadding(),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
                child: const NotificationsBanner(),
              ),
              const SizedBox(height: Spacing.s),
              for (final f in value) _FollowTile(follow: f, network: network),
            ],
          ),
        ),
        AsyncValue(:final error?) => MessageView.error(context, error, onRetry: () => ref.invalidate(followsProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _FollowTile extends ConsumerWidget {
  const _FollowTile({required this.follow, required this.network});

  final TripFollow follow;
  final Network? network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final line = network?.lines[follow.lineId];
    final headsign = line?.headsignOf(follow.directionId) ?? '';
    final today = follow.today;
    final muted = follow.enabled ? null : context.colors.onSurfaceVariant;
    return InkWell(
      onTap: () => unawaited(
        context.push(
          FollowPage.routeFor(
            stopId: follow.stopId,
            lineId: follow.lineId,
            directionId: follow.directionId,
            departureSeconds: follow.departureSeconds,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.m, context.pageMargin, Spacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.l,
          children: [
            LineBadge(line?.name ?? follow.lineId, muted: !follow.enabled),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.xs,
                children: [
                  // What the trip is: when it passes, where, and towards where.
                  Text(
                    '${clockOf(follow.departureSeconds)} · ${network?.stopById[follow.stopId]?.name ?? follow.stopId}',
                    style: context.textTheme.titleSmall?.copyWith(color: muted),
                  ),
                  if (headsign.isNotEmpty)
                    Text('→ $headsign', style: context.textTheme.bodyMedium?.copyWith(color: muted)),
                  // The setup: which days, how long before.
                  Text(
                    '${daysSummary(l10n, follow.days)} · ${l10n.followLeadsSummary(follow.leadMinutes.join(', '))}',
                    style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  // How today's trip is doing, when it is about to run.
                  if (follow.enabled && today != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: Wrap(
                        spacing: Spacing.s,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusTag(today.status),
                          if (today.status != ArrivalStatus.canceled && today.status != ArrivalStatus.suppressed)
                            Text(
                              today.minutes == null
                                  ? DateFormat.Hm().format(today.time.toLocal())
                                  : ArrivalText.inMinutes(l10n, today.minutes!),
                              style: context.textTheme.titleSmall,
                            ),
                          if (today.signal case final s?)
                            Text(ArrivalText.signal(l10n, s), style: context.textTheme.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: follow.enabled,
              onChanged: (v) => unawaited(
                ExceptionHandler.handle(
                  context,
                  () => ref.read(followsProvider(live: true).notifier).setEnabled(follow.id!, enabled: v),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

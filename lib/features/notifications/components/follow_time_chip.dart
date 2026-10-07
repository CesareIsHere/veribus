import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/notifications/follow_page.dart';
import 'package:veribus/features/notifications/providers/follow_providers.dart';

/// A time of the timetable you can tap to follow that trip (or edit its follow): a bell marks the ones followed.
class FollowTimeChip extends ConsumerWidget {
  const FollowTimeChip({
    required this.stopId,
    required this.lineId,
    required this.directionId,
    required this.seconds,
    required this.label,
    this.emphasized = false,
    super.key,
  });

  final String stopId;
  final String lineId;
  final int directionId;
  final int seconds;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followOfProvider('$stopId/$lineId/$directionId/$seconds')) != null;
    return FilterChip(
      label: Text(label),
      labelStyle: emphasized ? context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700) : null,
      selected: followed,
      showCheckmark: false,
      avatar: followed ? const Icon(Icons.notifications_active_outlined) : null,
      tooltip: followed ? context.l10n.followedMarker : context.l10n.followTrip,
      onSelected: (_) => unawaited(
        context.push(
          FollowPage.routeFor(stopId: stopId, lineId: lineId, directionId: directionId, departureSeconds: seconds),
        ),
      ),
    );
  }
}

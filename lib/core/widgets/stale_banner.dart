import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// RF-60: realtime data stopped for over 10 minutes, so every arrival is shown as scheduled. Empty otherwise.
class StaleBanner extends StatelessWidget {
  const StaleBanner(this.feed, {super.key});

  final FeedStatus? feed;

  @override
  Widget build(BuildContext context) {
    if (feed != FeedStatus.stale) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageMargin, vertical: Spacing.xs),
      child: Card.filled(
        child: ListTile(leading: const Icon(Icons.cloud_off_outlined), title: Text(context.l10n.realtimeUnavailable)),
      ),
    );
  }
}

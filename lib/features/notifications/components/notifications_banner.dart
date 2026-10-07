import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/notifications/providers/push_notifier.dart';
import 'package:veribus/services/push_notifications_service.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Shown above the followed trips while notices cannot reach this device: the permission was not given, or this build
/// has no push. Nothing while it works (or while the platform is still being asked).
class NotificationsBanner extends ConsumerWidget {
  const NotificationsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushProvider);
    if (push.available == null || push.ready) return const SizedBox.shrink();
    final l10n = context.l10n;
    final unavailable = push.available == false;
    // The system asks only twice: after that only the phone's settings can turn the notices on.
    final canAsk = !unavailable && push.permission == PushPermission.notDetermined;
    return Card.filled(
      margin: const EdgeInsets.only(top: Spacing.l),
      color: context.colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.s,
          children: [
            Row(
              spacing: Spacing.m,
              children: [
                Icon(Icons.notifications_off_outlined, color: context.colors.onErrorContainer),
                Expanded(
                  child: Text(
                    l10n.notificationsOff,
                    style: context.textTheme.titleSmall?.copyWith(color: context.colors.onErrorContainer),
                  ),
                ),
              ],
            ),
            Text(
              unavailable
                  ? l10n.notificationsUnavailable
                  : canAsk
                  ? l10n.notificationsOffBody
                  : l10n.notificationsBlocked,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onErrorContainer),
            ),
            if (canAsk)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => unawaited(ref.read(pushProvider.notifier).enable()),
                  child: Text(l10n.enableNotifications),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

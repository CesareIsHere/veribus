import 'package:emiliano_cesare_flutter_template/core/providers/connectivity_provider.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin status strip shown above the content while the device is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOnlineProvider).value == false;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: offline
          ? Material(
              color: context.colors.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.s),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: Spacing.s,
                    children: [
                      Icon(Icons.cloud_off, size: 18, color: context.colors.onErrorContainer),
                      Text(
                        context.l10n.offline,
                        style: context.textTheme.labelLarge?.copyWith(color: context.colors.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/widgets/alert_card.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/alerts/providers/alerts_provider.dart';
import 'package:veribus/features/line/line_page.dart';
import 'package:veribus/features/settings/components/settings_button.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Every active alert, most severe first (RF-50).
class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  static const route = '/alerts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.alerts), actions: const [SettingsButton()]),
      body: switch (ref.watch(alertsProvider)) {
        AsyncValue(:final value?) when value.isEmpty => MessageView(
          icon: Icons.check_circle_outline,
          title: l10n.noAlerts,
        ),
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: () => ref.refresh(alertsProvider.future),
          child: ListView.separated(
            padding: context.pagePadding(),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.s),
            itemBuilder: (context, i) => AlertCard(value[i], onTapLine: (id) => context.push(LinePage.route(id))),
          ),
        ),
        AsyncValue(:final error?) => MessageView.error(context, error, onRetry: () => ref.invalidate(alertsProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

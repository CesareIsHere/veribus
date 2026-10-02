import 'dart:async';

import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

IconData _severityIcon(int severity) => switch (severity) {
  2 => Icons.block,
  1 => Icons.warning_amber,
  _ => Icons.info_outline,
};

/// A service alert; severity is said by icon and text, not only by color (RF-52, RNF-07).
class AlertCard extends StatelessWidget {
  const AlertCard(this.alert, {this.onTapLine, this.initiallyExpanded = false, super.key});

  final ServiceAlert alert;
  final void Function(String lineId)? onTapLine;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      color: alert.isSevere ? context.colors.errorContainer : null,
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: initiallyExpanded,
        leading: Icon(_severityIcon(alert.severity)),
        title: Text(alert.title),
        childrenPadding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.l),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(alert.body),
          if (onTapLine != null && alert.lineIds.isNotEmpty)
            Wrap(
              spacing: Spacing.s,
              children: [for (final id in alert.lineIds) ActionChip(label: Text(id), onPressed: () => onTapLine!(id))],
            ),
        ],
      ),
    );
  }
}

/// One row standing for a list of alerts: icon and title of the most severe, the count; the full alerts open in a
/// bottom sheet on demand, so they do not push the content below out of sight. [alerts] must not be empty.
class AlertsTile extends StatelessWidget {
  const AlertsTile(this.alerts, {this.onTapLine, super.key});

  final List<ServiceAlert> alerts;
  final void Function(String lineId)? onTapLine;

  @override
  Widget build(BuildContext context) {
    final top = alerts.reduce((a, b) => b.severity > a.severity ? b : a);
    return ListTile(
      leading: Icon(_severityIcon(top.severity), color: top.isSevere ? context.colors.error : null),
      title: Text(context.l10n.alertsCount(alerts.length)),
      subtitle: Text(top.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _show(context),
    );
  }

  void _show(BuildContext context) {
    final sorted = [...alerts]..sort((a, b) => b.severity.compareTo(a.severity));
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: context.pagePadding(top: 0),
            children: [
              Text(context.l10n.alerts, style: context.textTheme.titleLarge),
              const SizedBox(height: Spacing.l),
              for (final alert in sorted)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.s),
                  child: AlertCard(alert, onTapLine: onTapLine, initiallyExpanded: sorted.length == 1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

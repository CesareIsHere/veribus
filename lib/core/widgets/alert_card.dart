import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// A service alert; severity is said by icon and text, not only by color (RF-52, RNF-07).
class AlertCard extends StatelessWidget {
  const AlertCard(this.alert, {this.onTapLine, super.key});

  final ServiceAlert alert;
  final void Function(String lineId)? onTapLine;

  @override
  Widget build(BuildContext context) {
    final severe = alert.severity == 2;
    return Card.outlined(
      color: severe ? context.colors.errorContainer : null,
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(severe ? Icons.block : (alert.severity == 1 ? Icons.warning_amber : Icons.info_outline)),
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

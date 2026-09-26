import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/styles/app_spacing.dart';

/// M3 list subheader, aligned with ListTile content (16dp inset).
/// Optional [action] (usually a TextButton) sits on the trailing edge.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, this.padding, super.key});

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(Spacing.l, Spacing.l, Spacing.s, Spacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: context.textTheme.titleSmall?.copyWith(color: context.colors.primary)),
          ),
          ?action,
        ],
      ),
    );
  }
}

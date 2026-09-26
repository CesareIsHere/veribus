import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';

/// M3 basic dialog. Returns true when the user confirms.
///
/// [confirmLabel] should be the action verb ("Delete", "Sign out"), never a
/// generic "OK". [destructive] adds the warning icon and error color.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: destructive ? const Icon(Icons.warning_amber_rounded) : null,
      iconColor: destructive ? context.colors.error : null,
      title: Text(title),
      content: Text(message),
      // Keeps 8dp between the buttons when they wrap on narrow screens.
      actionsOverflowButtonSpacing: Spacing.s,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        TextButton(
          style: destructive ? TextButton.styleFrom(foregroundColor: context.colors.error) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// M3 simple dialog with radio options. Returns the chosen value, or null if dismissed.
Future<T?> showChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required Map<T, String> options,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        RadioGroup<T>(
          groupValue: selected,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final MapEntry(key: value, value: label) in options.entries)
                RadioListTile<T>(value: value, title: Text(label)),
            ],
          ),
        ),
      ],
    ),
  );
}

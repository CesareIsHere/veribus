import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/settings/settings_page.dart';

/// The way into Settings (language, theme, app updates, support): the same gear, top right, on every tab.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.settings,
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => context.push(SettingsPage.route),
  );
}

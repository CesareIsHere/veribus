import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Layout shared by the auth pages: logo, headline, then the page [children]
/// in a centered column no wider than a form. Children manage their own gaps
/// with [Spacing] tokens (16 between fields, 8 between buttons, 24 between groups).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.title, required this.children, this.subtitle, super.key});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: context.pagePadding(maxWidth: ContentWidth.form, top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/logo.png', height: 64, semanticLabel: context.l10n.appTitle),
                const SizedBox(height: Spacing.xl),
                Text(title, style: context.textTheme.headlineSmall, textAlign: TextAlign.center),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(height: Spacing.s),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: Spacing.xxl),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/extensions/app_failure_extensions.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Centered empty/error state: icon, title, optional description and action.
class MessageView extends StatelessWidget {
  const MessageView({required this.icon, required this.title, this.description, this.action, super.key});

  /// Error state with a localized message and a retry button.
  factory MessageView.error(BuildContext context, Object error, {VoidCallback? onRetry}) => MessageView(
    icon: Icons.error_outline,
    title: AppFailure.from(error).message(context.l10n),
    action: onRetry == null
        ? null
        : FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(context.l10n.retry)),
  );

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.pageMargin),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ContentWidth.form),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: context.colors.onSurfaceVariant),
              const SizedBox(height: Spacing.l),
              Text(title, style: context.textTheme.titleMedium, textAlign: TextAlign.center),
              if (description case final description?) ...[
                const SizedBox(height: Spacing.s),
                Text(
                  description,
                  style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action case final action?) ...[const SizedBox(height: Spacing.xl), action],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/widgets/buttons/loading_button.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/styles/app_spacing.dart';

/// "or" divider + Google / Apple buttons, shown only where the active
/// backend supports them.
class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.xl),
        Row(
          spacing: Spacing.l,
          children: [
            const Expanded(child: Divider()),
            Text(
              context.l10n.orContinueWith,
              style: context.textTheme.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        LoadingButton(
          style: LoadingButtonStyle.outlined,
          onPressed: () => ExceptionHandler.handle(context, auth.signInWithGoogle),
          label: context.l10n.continueWithGoogle,
        ),
        const SizedBox(height: Spacing.s),
        LoadingButton(
          style: LoadingButtonStyle.outlined,
          icon: Icons.apple,
          onPressed: () => ExceptionHandler.handle(context, auth.signInWithApple),
          label: context.l10n.continueWithApple,
        ),
      ],
    );
  }
}

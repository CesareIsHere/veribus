import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/widgets/buttons/loading_button.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/auth/components/auth_scaffold.dart';
import 'package:veribus/features/auth/components/email_field.dart';
import 'package:veribus/styles/app_spacing.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  static const route = '/forgot-password';

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sent = await ExceptionHandler.handle(
      context,
      () => ref.read(authProvider.notifier).sendPasswordReset(_email.text.trim()),
      successMessage: context.l10n.resetEmailSent,
    );
    if (sent && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordSubtitle,
      children: [
        Form(
          key: _formKey,
          child: EmailField(controller: _email, onSubmitted: (_) => _submit()),
        ),
        const SizedBox(height: Spacing.xl),
        LoadingButton(onPressed: _submit, label: l10n.sendResetLink),
      ],
    );
  }
}

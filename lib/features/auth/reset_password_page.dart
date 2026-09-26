import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/utils/validators.dart';
import 'package:veribus/core/widgets/buttons/loading_button.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/auth/components/auth_scaffold.dart';
import 'package:veribus/features/auth/components/password_field.dart';
import 'package:veribus/features/auth/login_page.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Opened from the reset email: `/reset-password?token=...`
/// (Firebase links use `oobCode`: both are accepted by the router).
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({required this.token, super.key});

  static const route = '/reset-password';

  final String token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final done = await ExceptionHandler.handle(
      context,
      () => ref.read(authProvider.notifier).confirmPasswordReset(token: widget.token, newPassword: _password.text),
      successMessage: context.l10n.passwordUpdated,
    );
    if (done && mounted) context.go(LoginPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.resetPasswordTitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.l,
            children: [
              PasswordField(
                controller: _password,
                label: l10n.newPassword,
                newPassword: true,
                validator: Validators.password(l10n),
              ),
              PasswordField(
                controller: _confirm,
                label: l10n.confirmPassword,
                newPassword: true,
                validator: Validators.matches(l10n, () => _password.text),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        LoadingButton(onPressed: widget.token.isEmpty ? null : _submit, label: l10n.savePassword),
      ],
    );
  }
}

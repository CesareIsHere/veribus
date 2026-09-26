import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/utils/validators.dart';
import 'package:veribus/core/widgets/buttons/loading_button.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/auth/components/auth_scaffold.dart';
import 'package:veribus/features/auth/components/email_field.dart';
import 'package:veribus/features/auth/components/password_field.dart';
import 'package:veribus/styles/app_spacing.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  static const route = '/register';

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ExceptionHandler.handle(
      context,
      () => ref
          .read(authProvider.notifier)
          .signUp(email: _email.text.trim(), password: _password.text, displayName: _name.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.registerTitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spacing.l,
              children: [
                TextFormField(
                  controller: _name,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.required(l10n),
                  decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.person_outline)),
                ),
                EmailField(controller: _email),
                PasswordField(
                  controller: _password,
                  label: l10n.password,
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
        ),
        const SizedBox(height: Spacing.xl),
        LoadingButton(onPressed: _submit, label: l10n.createAccount),
      ],
    );
  }
}

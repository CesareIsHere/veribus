import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/utils/validators.dart';
import 'package:veribus/core/widgets/buttons/loading_button.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/auth/components/auth_scaffold.dart';
import 'package:veribus/features/auth/components/email_field.dart';
import 'package:veribus/features/auth/components/password_field.dart';
import 'package:veribus/features/auth/components/social_login_buttons.dart'; // feature:social_login
import 'package:veribus/features/auth/forgot_password_page.dart';
import 'package:veribus/features/auth/register_page.dart';
import 'package:veribus/styles/app_spacing.dart';

/// On success the router redirect moves the user away (see router.dart).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ExceptionHandler.handle(
      context,
      () => ref.read(authProvider.notifier).signIn(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spacing.l,
              children: [
                EmailField(controller: _email),
                PasswordField(
                  controller: _password,
                  label: l10n.password,
                  validator: Validators.required(l10n),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: () => context.push(ForgotPasswordPage.route), child: Text(l10n.forgotPassword)),
        ),
        const SizedBox(height: Spacing.l),
        LoadingButton(onPressed: _submit, label: l10n.signIn),
        if (Features.socialLogin) const SocialLoginButtons(), // feature:social_login
        const SizedBox(height: Spacing.xl),
        TextButton(onPressed: () => context.push(RegisterPage.route), child: Text(l10n.noAccountRegister)),
      ],
    );
  }
}

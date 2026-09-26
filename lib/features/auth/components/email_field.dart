import 'package:emiliano_cesare_flutter_template/core/utils/validators.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

/// Email input with keyboard, autofill and validation set up.
class EmailField extends StatelessWidget {
  const EmailField({required this.controller, this.onSubmitted, super.key});

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: Validators.email(context.l10n),
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(labelText: context.l10n.email, prefixIcon: const Icon(Icons.mail_outline)),
    );
  }
}

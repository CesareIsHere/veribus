import 'package:emiliano_cesare_flutter_template/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Localized form validators: `validator: Validators.email(context.l10n)`.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static FormFieldValidator<String> required(AppLocalizations l10n) =>
      (value) => (value == null || value.trim().isEmpty) ? l10n.validationRequired : null;

  static FormFieldValidator<String> email(AppLocalizations l10n) => (value) {
    if (value == null || value.trim().isEmpty) return l10n.validationRequired;
    return _emailRegex.hasMatch(value.trim()) ? null : l10n.validationEmail;
  };

  /// At least 8 characters, one letter and one digit.
  static FormFieldValidator<String> password(AppLocalizations l10n) => (value) {
    if (value == null || value.isEmpty) return l10n.validationRequired;
    final strong = value.length >= 8 && value.contains(RegExp('[A-Za-z]')) && value.contains(RegExp(r'\d'));
    return strong ? null : l10n.validationPassword;
  };

  static FormFieldValidator<String> matches(AppLocalizations l10n, String Function() other) =>
      (value) => value == other() ? null : l10n.validationPasswordsMatch;
}

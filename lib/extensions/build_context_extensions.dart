import 'package:flutter/material.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/styles/app_theme.dart';

extension BuildContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// M3 snackbar (inverse surface), replacing the current one.
  void showSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }
}

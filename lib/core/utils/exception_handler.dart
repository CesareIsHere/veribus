import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/core/utils/logger.dart';
import 'package:veribus/extensions/app_failure_extensions.dart';
import 'package:veribus/extensions/build_context_extensions.dart';

/// Runs a user action and turns any error into a localized snackbar.
///
/// ```dart
/// final ok = await ExceptionHandler.handle(context, () => repo.save(x));
/// ```
abstract final class ExceptionHandler {
  static Future<bool> handle(BuildContext context, Future<void> Function() action, {String? successMessage}) async {
    try {
      await action();
      if (successMessage != null && context.mounted) context.showSnackBar(successMessage);
      return true;
    } on Object catch (error, stack) {
      final failure = report(error, stack);
      if (context.mounted) context.showSnackBar(failure.message(context.l10n));
      return false;
    }
  }

  /// Logs the error, sends unexpected ones to Sentry, returns the mapped failure.
  static AppFailure report(Object error, [StackTrace? stack]) {
    final failure = AppFailure.from(error);
    talker.handle(error, stack);
    if (failure.isUnexpected) Sentry.captureException(error, stackTrace: stack).ignore();
    return failure;
  }
}

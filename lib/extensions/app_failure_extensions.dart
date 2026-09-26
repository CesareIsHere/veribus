import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';

/// Localized, user-facing text for a failure (kept out of the data layer).
extension AppFailureMessage on AppFailure {
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    ServerFailure(:final serverMessage) => serverMessage ?? l10n.errorServer,
    NotSupportedFailure() => l10n.errorNotSupported,
    AuthFailure(:final code) => switch (code) {
      AuthErrorCode.invalidCredentials => l10n.errorInvalidCredentials,
      AuthErrorCode.emailInUse => l10n.errorEmailInUse,
      AuthErrorCode.weakPassword => l10n.errorWeakPassword,
      AuthErrorCode.tooManyRequests => l10n.errorTooManyRequests,
      AuthErrorCode.requiresRecentLogin => l10n.errorRequiresRecentLogin,
      AuthErrorCode.cancelled => l10n.errorCancelled,
      AuthErrorCode.emailNotConfirmed => l10n.errorEmailNotConfirmed,
    },
    UnknownFailure() => l10n.errorUnknown,
  };
}

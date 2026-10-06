import 'package:flutter/material.dart';

/// Compile-time configuration.
///
/// Values come from `--dart-define-from-file=env/<stage>.json`.
/// Running without a define file gives a safe default: mock backend,
/// every optional feature off.
abstract final class AppConfig {
  static const stage = String.fromEnvironment('APP_STAGE', defaultValue: 'dev');
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'Veribus');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const appStoreId = String.fromEnvironment('APP_STORE_ID');

  /// Where new builds are published: the GitHub Releases page, which `release.yml` fills with the APK.
  static const releasesUrl = String.fromEnvironment(
    'RELEASES_URL',
    defaultValue: 'https://github.com/CesareIsHere/veribus/releases/latest',
  );
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Where OAuth (Supabase Google on web, Apple on Android) returns on mobile:
  /// an App Link handled by the app (see AndroidManifest). On web the Site URL is used.
  static const authRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');
  static const _seedColor = String.fromEnvironment('SEED_COLOR', defaultValue: '0xFF3F51B5');
  static const _backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');

  /// Mock mode only (`env/mock.json`): start signed in and at a fixed position ("lat,lon"), so every screen
  /// can be opened without typing credentials or granting the location.
  static const mockSignedIn = bool.fromEnvironment('MOCK_SIGNED_IN');
  static const mockPosition = String.fromEnvironment('MOCK_POSITION');

  static bool get isProd => stage == 'prod';
  static Color get seedColor => Color(int.parse(_seedColor));
  static Backend get backend => Backend.values.byName(_backend);
}

/// Where auth and data live. Switch it with the `BACKEND` env key.
enum Backend {
  /// In-memory fakes: the app runs with no server at all.
  mock,

  /// Supabase Auth + the `api` schema RPCs + Storage. Schema in `supabase/migrations`.
  supabase,
}

/// Feature flags. `const` so the compiler drops code behind a `false` flag.
///
/// To remove a feature for good (code + packages) run
/// `dart run tool/setup.dart`.
abstract final class Features {
  static const socialLogin = bool.fromEnvironment('FEATURE_SOCIAL_LOGIN');
  static const connectivity = bool.fromEnvironment('FEATURE_CONNECTIVITY');
  static const feedback = bool.fromEnvironment('FEATURE_FEEDBACK');
}

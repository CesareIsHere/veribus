import 'package:flutter/material.dart';

/// Compile-time configuration.
///
/// Values come from `--dart-define-from-file=env/<stage>.json`.
/// Running without a define file gives a safe default: mock backend,
/// every optional feature off.
abstract final class AppConfig {
  static const stage = String.fromEnvironment('APP_STAGE', defaultValue: 'dev');
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'Template');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api/v1');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const appStoreId = String.fromEnvironment('APP_STORE_ID');
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Where OAuth (Supabase Google on web, Apple on Android) returns on mobile:
  /// an App Link handled by the app (see AndroidManifest). On web the Site URL is used.
  static const authRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');
  static const fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
  static const revenueCatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const revenueCatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  static const revenueCatEntitlement = String.fromEnvironment('REVENUECAT_ENTITLEMENT', defaultValue: 'premium');
  static const currency = String.fromEnvironment('CURRENCY', defaultValue: 'EUR');
  static const aiModel = String.fromEnvironment('AI_MODEL', defaultValue: 'gemini-2.5-flash');
  static const _seedColor = String.fromEnvironment('SEED_COLOR', defaultValue: '0xFF3F51B5');
  static const _backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');

  static bool get isProd => stage == 'prod';
  static Color get seedColor => Color(int.parse(_seedColor));
  static Backend get backend => Backend.values.byName(_backend);

  /// Firebase must be initialized when any Firebase-backed piece is on.
  static bool get usesFirebase =>
      backend == Backend.firebase || Features.push || Features.remoteConfig || Features.analytics || Features.ai;
}

/// Where auth and data live. Switch it with the `BACKEND` env key.
enum Backend {
  /// In-memory fakes: the app runs with no server at all.
  mock,

  /// Your own REST API (JWT access + refresh token).
  rest,

  /// Firebase Auth + Firestore + Storage.
  firebase,

  /// Supabase Auth + Postgres (RLS) + Storage. Schema in `supabase/migrations`.
  supabase,
}

/// Feature flags. `const` so the compiler drops code behind a `false` flag.
///
/// To remove a feature for good (code + packages) run
/// `dart run tool/setup.dart`.
abstract final class Features {
  static const onboarding = bool.fromEnvironment('FEATURE_ONBOARDING');
  static const socialLogin = bool.fromEnvironment('FEATURE_SOCIAL_LOGIN');
  static const connectivity = bool.fromEnvironment('FEATURE_CONNECTIVITY');
  static const appReview = bool.fromEnvironment('FEATURE_APP_REVIEW');
  static const feedback = bool.fromEnvironment('FEATURE_FEEDBACK');
  static const biometricLock = bool.fromEnvironment('FEATURE_BIOMETRIC_LOCK');
  static const push = bool.fromEnvironment('FEATURE_PUSH');
  static const remoteConfig = bool.fromEnvironment('FEATURE_REMOTE_CONFIG');
  static const analytics = bool.fromEnvironment('FEATURE_ANALYTICS');
  static const payments = bool.fromEnvironment('FEATURE_PAYMENTS');
  static const ai = bool.fromEnvironment('FEATURE_AI');

  /// The personal-finance demo app. `tool/setup.dart --without demo` removes it.
  static const demo = bool.fromEnvironment('FEATURE_DEMO');
}

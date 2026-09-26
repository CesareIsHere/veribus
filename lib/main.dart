import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // backend:supabase
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:veribus/core/app/app.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';
import 'package:veribus/core/utils/logger.dart';
import 'package:veribus/core/widgets/app_restart/restart_widget.dart';

/// Run with: `flutter run --dart-define-from-file=env/dev.json`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: clean URLs (no #) that follow imperative navigation too.
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Log every uncaught error (Sentry, when on, hooks in on top of these).
  FlutterError.onError = (details) => talker.handle(details.exception, details.stack);
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());

  // backend:supabase:start
  if (AppConfig.backend == Backend.supabase) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
  }
  // backend:supabase:end

  final app = RestartWidget(
    child: ProviderScope(
      observers: [
        TalkerRiverpodObserver(
          talker: talker,
          // Log which provider changed, not its whole state (lists get huge).
          settings: const TalkerRiverpodLoggerSettings(printStateFullData: false),
        ),
      ],
      // No automatic retries: errors surface immediately, users retry explicitly.
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );

  if (AppConfig.sentryDsn.isEmpty) return runApp(app);
  await SentryFlutter.init(
    (options) => options
      ..dsn = AppConfig.sentryDsn
      ..environment = AppConfig.stage
      ..tracesSampleRate = AppConfig.isProd ? 0.2 : 1.0,
    appRunner: () => runApp(SentryWidget(child: app)),
  );
}

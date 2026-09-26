import 'dart:async';

import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/navigation/router.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/locale_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/theme_mode_notifier.dart';
import 'package:emiliano_cesare_flutter_template/features/app_gate/components/app_gate.dart'; // feature:remote_config
import 'package:emiliano_cesare_flutter_template/features/biometric_lock/components/app_lock_gate.dart'; // feature:biometric_lock
import 'package:emiliano_cesare_flutter_template/features/notifications/providers/push_notifications_provider.dart'; // feature:push
import 'package:emiliano_cesare_flutter_template/features/payments/providers/payments_provider.dart'; // feature:payments
import 'package:emiliano_cesare_flutter_template/l10n/gen/app_localizations.dart';
import 'package:emiliano_cesare_flutter_template/services/analytics_service.dart'; // feature:analytics
import 'package:emiliano_cesare_flutter_template/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side-effect providers that must live as long as the app.
    if (Features.push) ref.watch(pushNotificationsProvider); // feature:push
    if (Features.payments) ref.watch(paymentsProvider); // feature:payments
    ref.listen(authProvider, (_, next) {
      final user = next.value;
      unawaited(
        Future.sync(
          () =>
              Sentry.configureScope((s) => s.setUser(user == null ? null : SentryUser(id: user.id, email: user.email))),
        ),
      );
      AnalyticsService.setUserId(user?.id).ignore(); // feature:analytics
    });

    return MaterialApp.router(
      onGenerateTitle: (_) => AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // DateFormat & co. follow the app language.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        var app = child!;
        if (Features.remoteConfig) app = AppGate(child: app); // feature:remote_config
        if (Features.biometricLock) app = AppLockGate(child: app); // feature:biometric_lock
        // Tap outside a text field closes the keyboard.
        return GestureDetector(onTap: () => FocusManager.instance.primaryFocus?.unfocus(), child: app);
      },
    );
  }
}

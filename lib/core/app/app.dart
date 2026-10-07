import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/navigation/router.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/package_info_provider.dart';
import 'package:veribus/core/providers/theme_mode_notifier.dart';
import 'package:veribus/core/widgets/update_required_page.dart';
import 'package:veribus/features/notifications/providers/push_notifier.dart'; // feature:push
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/styles/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side-effect providers that must live as long as the app.
    ref.listen(authProvider, (_, next) {
      final user = next.value;
      unawaited(
        Future.sync(
          () =>
              Sentry.configureScope((s) => s.setUser(user == null ? null : SentryUser(id: user.id, email: user.email))),
        ),
      );
    });

    if (Features.push) ref.listen(pushProvider, (_, _) {}); // feature:push

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
        final minVersion = ref.watch(networkInfoProvider).value?.minAppVersion;
        final version = ref.watch(packageInfoProvider).value;
        // RNF-08: below the minimum version the API may have changed incompatibly.
        final app = minVersion != null && version != null && isOlderVersion(version.version, minVersion)
            ? UpdateRequiredPage(packageName: version.packageName)
            : child!;
        // Tap outside a text field closes the keyboard.
        return GestureDetector(onTap: () => FocusManager.instance.primaryFocus?.unfocus(), child: app);
      },
    );
  }
}

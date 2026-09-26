import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/navigation/app_shell.dart';
import 'package:veribus/core/navigation/pages/not_found_page.dart';
import 'package:veribus/core/navigation/pages/splash_page.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/logger.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/auth/forgot_password_page.dart';
import 'package:veribus/features/auth/login_page.dart';
import 'package:veribus/features/auth/register_page.dart';
import 'package:veribus/features/auth/reset_password_page.dart';
import 'package:veribus/features/home/home_page.dart';
import 'package:veribus/features/settings/profile_page.dart';
import 'package:veribus/features/settings/settings_page.dart';
import 'package:veribus/models/user/user_model.dart';

part 'router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Reachable while signed out.
const Set<String> _publicRoutes = {
  LoginPage.route,
  RegisterPage.route,
  ForgotPasswordPage.route,
  ResetPasswordPage.route,
};

/// Pages the user should never "come back" to after a redirect.
const Set<String> _transitRoutes = {SplashPage.route, '/onboarding'};

/// All navigation rules in one pure function (unit-tested).
///
/// - session still loading → splash (remembering the requested page)
/// - onboarding not done → onboarding
/// - signed out on a private page → `login?from=<page>`
/// - signed in on a public/transit page → `from` or home
String? appRedirect({required AsyncValue<UserModel?> auth, required Uri uri, bool onboardingDone = true}) {
  final path = uri.path;
  final from = uri.queryParameters['from'];
  final requested = _transitRoutes.contains(path) ? from : uri.toString();

  if (!auth.hasValue && !auth.hasError) {
    return path == SplashPage.route ? null : _withFrom(SplashPage.route, requested);
  }
  if (!onboardingDone) return path == '/onboarding' ? null : _withFrom('/onboarding', requested);

  final signedIn = auth.value != null;
  final isPublic = _publicRoutes.contains(path);
  if (!signedIn) return isPublic ? null : _withFrom(LoginPage.route, requested);
  if (isPublic || _transitRoutes.contains(path)) {
    return _isReturnTarget(from) ? from : HomePage.route;
  }
  return null;
}

String _withFrom(String path, String? from) => Uri(
  path: path,
  queryParameters: _isReturnTarget(from) && from != HomePage.route ? {'from': from} : null,
).toString();

/// A page worth returning to after login: an in-app path (never an external
/// or protocol-relative URL, to avoid open redirects) that isn't a public or
/// transit page itself.
bool _isReturnTarget(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return false;
  final path = Uri.parse(from).path;
  return !_publicRoutes.contains(path) && !_transitRoutes.contains(path);
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = ValueNotifier(0);
  void bump(Object? _, Object? _) => refresh.value++;
  ref
    ..listen(authProvider, bump)
    ..onDispose(refresh.dispose);

  final tabs = <({String route, Widget page, List<RouteBase> routes, ShellDestination Function(BuildContext) nav})>[
    if (!Features.demo)
      (
        route: HomePage.route,
        page: const HomePage(),
        routes: const <RouteBase>[],
        nav: (c) => (icon: Icons.home_outlined, selectedIcon: Icons.home, label: c.l10n.home),
      ),
    (
      route: SettingsPage.route,
      page: const SettingsPage(),
      routes: [
        GoRoute(path: 'profile', builder: (_, _) => const ProfilePage()),
        GoRoute(
          path: 'logs',
          builder: (_, _) => TalkerScreen(talker: talker),
        ),
      ],
      nav: (c) => (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: c.l10n.settings),
    ),
  ];

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: HomePage.route,
    refreshListenable: refresh,
    debugLogDiagnostics: !AppConfig.isProd,
    observers: [if (AppConfig.sentryDsn.isNotEmpty) SentryNavigatorObserver()],
    redirect: (_, state) => appRedirect(auth: ref.read(authProvider), uri: state.uri),
    errorBuilder: (_, _) => const NotFoundPage(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => HomePage.route),
      GoRoute(path: SplashPage.route, builder: (_, _) => const SplashPage()),
      GoRoute(path: LoginPage.route, builder: (_, _) => const LoginPage()),
      GoRoute(path: RegisterPage.route, builder: (_, _) => const RegisterPage()),
      GoRoute(path: ForgotPasswordPage.route, builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(
        path: ResetPasswordPage.route,
        builder: (_, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token'] ?? state.uri.queryParameters['oobCode'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) => AppShell(shell: shell, destinations: [for (final t in tabs) t.nav(context)]),
        branches: [
          for (final t in tabs)
            StatefulShellBranch(
              routes: [GoRoute(path: t.route, builder: (_, _) => t.page, routes: t.routes)],
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

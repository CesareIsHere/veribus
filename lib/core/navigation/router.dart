import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/navigation/app_shell.dart';
import 'package:emiliano_cesare_flutter_template/core/navigation/pages/not_found_page.dart';
import 'package:emiliano_cesare_flutter_template/core/navigation/pages/splash_page.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/logger.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/ai/ai_chat_page.dart'; // feature:ai
import 'package:emiliano_cesare_flutter_template/features/auth/forgot_password_page.dart';
import 'package:emiliano_cesare_flutter_template/features/auth/login_page.dart';
import 'package:emiliano_cesare_flutter_template/features/auth/register_page.dart';
import 'package:emiliano_cesare_flutter_template/features/auth/reset_password_page.dart';
import 'package:emiliano_cesare_flutter_template/features/dashboard/dashboard_page.dart'; // feature:demo
import 'package:emiliano_cesare_flutter_template/features/home/home_page.dart';
import 'package:emiliano_cesare_flutter_template/features/onboarding/onboarding_page.dart'; // feature:onboarding
import 'package:emiliano_cesare_flutter_template/features/onboarding/providers/onboarding_notifier.dart'; // feature:onboarding
import 'package:emiliano_cesare_flutter_template/features/payments/paywall_page.dart'; // feature:payments
import 'package:emiliano_cesare_flutter_template/features/settings/profile_page.dart';
import 'package:emiliano_cesare_flutter_template/features/settings/settings_page.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/transaction_form_page.dart'; // feature:demo
import 'package:emiliano_cesare_flutter_template/features/transactions/transactions_page.dart'; // feature:demo
import 'package:emiliano_cesare_flutter_template/models/user/user_model.dart';
import 'package:emiliano_cesare_flutter_template/services/analytics_service.dart'; // feature:analytics
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    ..listen(onboardingProvider, bump) // feature:onboarding
    ..onDispose(refresh.dispose);

  final tabs = <({String route, Widget page, List<RouteBase> routes, ShellDestination Function(BuildContext) nav})>[
    // feature:demo:start
    if (Features.demo) ...[
      (
        route: DashboardPage.route,
        page: const DashboardPage(),
        routes: const <RouteBase>[],
        nav: (c) => (icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, label: c.l10n.overview),
      ),
      (
        route: TransactionsPage.route,
        page: const TransactionsPage(),
        // Full-screen dialogs above the shell (root navigator).
        routes: <RouteBase>[
          GoRoute(path: 'new', parentNavigatorKey: rootNavigatorKey, builder: (_, _) => const TransactionFormPage()),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) => TransactionFormPage(id: state.pathParameters['id']),
          ),
        ],
        nav: (c) => (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: c.l10n.transactions),
      ),
    ],
    // feature:demo:end
    if (!Features.demo)
      (
        route: HomePage.route,
        page: const HomePage(),
        routes: const <RouteBase>[],
        nav: (c) => (icon: Icons.home_outlined, selectedIcon: Icons.home, label: c.l10n.home),
      ),
    // feature:ai:start
    if (Features.ai)
      (
        route: AiChatPage.route,
        page: const AiChatPage(),
        routes: const [],
        nav: (c) => (icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: c.l10n.assistant),
      ),
    // feature:ai:end
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
    observers: [
      ...AnalyticsService.observers, // feature:analytics
      if (AppConfig.sentryDsn.isNotEmpty) SentryNavigatorObserver(),
    ],
    redirect: (_, state) => appRedirect(
      auth: ref.read(authProvider),
      uri: state.uri,
      onboardingDone: !Features.onboarding || ref.read(onboardingProvider), // feature:onboarding
    ),
    errorBuilder: (_, _) => const NotFoundPage(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => HomePage.route),
      GoRoute(path: SplashPage.route, builder: (_, _) => const SplashPage()),
      GoRoute(path: OnboardingPage.route, builder: (_, _) => const OnboardingPage()), // feature:onboarding
      GoRoute(path: LoginPage.route, builder: (_, _) => const LoginPage()),
      GoRoute(path: RegisterPage.route, builder: (_, _) => const RegisterPage()),
      GoRoute(path: ForgotPasswordPage.route, builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(
        path: ResetPasswordPage.route,
        builder: (_, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token'] ?? state.uri.queryParameters['oobCode'] ?? ''),
      ),
      GoRoute(path: PaywallPage.route, builder: (_, _) => const PaywallPage()), // feature:payments
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

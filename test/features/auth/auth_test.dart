import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/features/auth/login_page.dart';
import 'package:emiliano_cesare_flutter_template/l10n/gen/app_localizations.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/auth_repository_provider.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/mock_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(MockAuthRepository(latency: Duration.zero))],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('AuthNotifier', () {
    test('sign in, update profile, sign out', () async {
      final c = container();
      final sub = c.listen(authProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await c.read(authProvider.future), isNull);

      await c.read(authProvider.notifier).signIn(email: 'mario@rossi.it', password: 'secret123');
      await pumpEventQueue();
      expect(c.read(authProvider).value?.email, 'mario@rossi.it');

      await c.read(authProvider.notifier).updateProfile(displayName: 'Mario');
      await pumpEventQueue();
      expect(c.read(authProvider).value?.displayName, 'Mario');

      await c.read(authProvider.notifier).signOut();
      await pumpEventQueue();
      expect(c.read(authProvider).value, isNull);
    });

    test('wrong password surfaces an AuthFailure', () async {
      final c = container();
      expect(
        c.read(authProvider.notifier).signIn(email: 'a@b.it', password: 'wrongpass'),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', AuthErrorCode.invalidCredentials)),
      );
    });
  });

  testWidgets('LoginPage validates, then signs in', (tester) async {
    final c = container();
    final sub = c.listen(authProvider, (_, _) {});
    addTearDown(sub.close);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(LoginPage)));

    await tester.tap(find.text(l10n.signIn));
    await tester.pump();
    expect(find.text(l10n.validationRequired), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'mario@rossi.it');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text(l10n.signIn));
    await tester.pumpAndSettle();
    expect(c.read(authProvider).value?.email, 'mario@rossi.it');
  });
}

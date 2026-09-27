import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/core/navigation/router.dart';
import 'package:veribus/models/user/user_model.dart';

void main() {
  const user = UserModel(id: '1', email: 'a@b.c');
  const signedIn = AsyncData<UserModel?>(user);
  const signedOut = AsyncData<UserModel?>(null);
  const loading = AsyncLoading<UserModel?>();

  String? redirect(AsyncValue<UserModel?> auth, String location, {bool onboardingDone = true}) =>
      appRedirect(auth: auth, uri: Uri.parse(location), onboardingDone: onboardingDone);

  group('appRedirect', () {
    test('loading session goes to splash and remembers the page', () {
      expect(redirect(loading, '/settings/profile'), '/splash?from=%2Fsettings%2Fprofile');
      expect(redirect(loading, '/splash'), isNull);
    });

    test('onboarding comes first', () {
      expect(redirect(signedOut, '/login', onboardingDone: false), '/onboarding');
      expect(redirect(signedOut, '/onboarding', onboardingDone: false), isNull);
    });

    test('signed out: private pages go to login with from, public pages stay', () {
      expect(redirect(signedOut, '/settings'), '/login?from=%2Fsettings');
      expect(redirect(signedOut, '/'), '/login');
      expect(redirect(signedOut, '/register'), isNull);
      expect(redirect(signedOut, '/reset-password?token=x'), isNull);
    });

    test('splash forwards the remembered page', () {
      expect(redirect(signedOut, '/splash?from=%2Fsettings'), '/login?from=%2Fsettings');
      expect(redirect(signedIn, '/splash?from=%2Fsettings'), '/settings');
    });

    test('signed in: leaves auth pages, honours only safe from', () {
      expect(redirect(signedIn, '/login'), '/nearby');
      expect(redirect(signedIn, '/login?from=%2Fsettings'), '/settings');
      expect(redirect(signedIn, '/login?from=https%3A%2F%2Fevil.com'), '/nearby');
      expect(redirect(signedIn, '/login?from=%2Flogin'), '/nearby');
      expect(redirect(signedIn, '/login?from=%2F%2Fevil.com'), '/nearby');
      expect(redirect(signedIn, '/settings'), isNull);
    });

    test('the app opens on favorites when there are some, otherwise nearby (RF-42)', () {
      expect(redirect(signedIn, '/'), '/nearby');
      expect(appRedirect(auth: signedIn, uri: Uri.parse('/'), home: '/favorites'), '/favorites');
    });

    test('auth error counts as signed out', () {
      expect(redirect(AsyncError<UserModel?>(Exception(), StackTrace.empty), '/'), '/login');
    });
  });
}

import 'dart:convert';

import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/supabase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;

  /// Every auth request answers with [status] and [body].
  SupabaseAuthRepository repoAnswering(int status, Map<String, dynamic> body) {
    client = SupabaseClient(
      'https://test.supabase.co',
      'sb_publishable_test',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json', 'x-supabase-api-version': '2024-01-01'},
        ),
      ),
      // PKCE needs persistent storage, which plain clients don't have.
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    return SupabaseAuthRepository(client: client);
  }

  tearDown(() => client.dispose());

  Matcher failsWith(AuthErrorCode code) => throwsA(isA<AuthFailure>().having((f) => f.code, 'code', code));

  test('maps Supabase error codes to AuthFailures', () async {
    final repo = repoAnswering(400, {'code': 'invalid_credentials', 'msg': 'Invalid login'});
    await expectLater(
      repo.signInWithEmail(email: 'a@b.co', password: 'x'),
      failsWith(AuthErrorCode.invalidCredentials),
    );
  });

  test('sign-up without a session asks to confirm the email', () async {
    final repo = repoAnswering(200, {
      'id': '6b0c5d1e-0000-4000-8000-000000000001',
      'aud': 'authenticated',
      'email': 'a@b.co',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-09-26T10:00:00Z',
    });
    await expectLater(
      repo.signUpWithEmail(email: 'a@b.co', password: 'secret123'),
      failsWith(AuthErrorCode.emailNotConfirmed),
    );
  });
}

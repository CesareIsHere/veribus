import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/firebase_auth_repository.dart'; // backend:firebase
import 'package:emiliano_cesare_flutter_template/repositories/auth/i_auth_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/mock_auth_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/rest_auth_repository.dart'; // backend:rest
import 'package:emiliano_cesare_flutter_template/repositories/auth/supabase_auth_repository.dart'; // backend:supabase
import 'package:emiliano_cesare_flutter_template/repositories/session/session_repository.dart'; // backend:rest
import 'package:emiliano_cesare_flutter_template/services/api/api_client.dart'; // backend:rest
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_provider.g.dart';

/// The only place that knows which backend is active.
@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockAuthRepository(),
  // backend:rest:start
  Backend.rest => RestAuthRepository(
    ref.watch(sessionRepositoryProvider),
    createAuthClient(),
    () => ref.read(apiClientProvider),
  ),
  // backend:rest:end
  Backend.firebase => FirebaseAuthRepository(), // backend:firebase
  Backend.supabase => SupabaseAuthRepository(), // backend:supabase
  // tool/setup.dart enables this fallback when it removes a backend.
  // backend:fallback _ => MockAuthRepository(),
};

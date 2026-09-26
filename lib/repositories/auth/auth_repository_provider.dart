import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/repositories/auth/i_auth_repository.dart';
import 'package:veribus/repositories/auth/mock_auth_repository.dart';
import 'package:veribus/repositories/auth/supabase_auth_repository.dart'; // backend:supabase

part 'auth_repository_provider.g.dart';

/// The only place that knows which backend is active.
@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockAuthRepository(),
  Backend.supabase => SupabaseAuthRepository(), // backend:supabase
  // tool/setup.dart enables this fallback when it removes a backend.
  _ => MockAuthRepository(),
};

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/repositories/journeys/i_journeys_repository.dart';
import 'package:veribus/repositories/journeys/mock_journeys_repository.dart';
import 'package:veribus/repositories/journeys/supabase_journeys_repository.dart'; // backend:supabase

part 'journeys_repository_provider.g.dart';

/// The only place that knows which backend is active.
@Riverpod(keepAlive: true)
IJourneysRepository journeysRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockJourneysRepository(),
  Backend.supabase => SupabaseJourneysRepository(), // backend:supabase
};

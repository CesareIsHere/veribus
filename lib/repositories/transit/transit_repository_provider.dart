import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/repositories/transit/i_transit_repository.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/supabase_transit_repository.dart'; // backend:supabase

part 'transit_repository_provider.g.dart';

/// The only place that knows which backend is active.
@Riverpod(keepAlive: true)
ITransitRepository transitRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockTransitRepository(),
  Backend.supabase => SupabaseTransitRepository(), // backend:supabase
};

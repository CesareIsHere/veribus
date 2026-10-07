import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/repositories/follow/i_follow_repository.dart';
import 'package:veribus/repositories/follow/mock_follow_repository.dart';
import 'package:veribus/repositories/follow/supabase_follow_repository.dart'; // backend:supabase

part 'follow_repository_provider.g.dart';

/// The only place that knows which backend holds the followed trips.
@Riverpod(keepAlive: true)
IFollowRepository followRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockFollowRepository(),
  Backend.supabase => SupabaseFollowRepository(), // backend:supabase
};

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'alerts_provider.g.dart';

@riverpod
Future<List<ServiceAlert>> alerts(Ref ref) => ref.watch(transitRepositoryProvider).alerts();

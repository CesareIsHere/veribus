import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'network_provider.g.dart';

/// Active network version and remote config; checked at every app start. The API needs a signed-in user,
/// so it runs again when the user changes.
@Riverpod(keepAlive: true)
Future<NetworkInfo> networkInfo(Ref ref) async {
  final user = await ref.watch(authProvider.selectAsync((u) => u?.id));
  if (user == null) throw const UnauthorizedFailure();
  return await ref.watch(transitRepositoryProvider).networkInfo();
}

/// Stops and lines, in memory for the whole session (search and nearby run on the phone: RF-11).
@Riverpod(keepAlive: true)
Future<Network> network(Ref ref) async {
  final info = await ref.watch(networkInfoProvider.future);
  return await ref.watch(transitRepositoryProvider).network(info);
}

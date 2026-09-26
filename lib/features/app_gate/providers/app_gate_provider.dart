import 'package:emiliano_cesare_flutter_template/core/providers/package_info_provider.dart';
import 'package:emiliano_cesare_flutter_template/services/remote_config_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_gate_provider.g.dart';

enum AppGateStatus { ok, updateRequired, maintenance }

@Riverpod(keepAlive: true)
Future<AppGateStatus> appGate(Ref ref) async {
  final config = await ref.watch(remoteConfigServiceProvider).load();
  if (config.maintenance) return AppGateStatus.maintenance;
  final current = (await ref.watch(packageInfoProvider.future)).version;
  return isVersionLower(current, config.minVersion) ? AppGateStatus.updateRequired : AppGateStatus.ok;
}

/// Semver compare on `major.minor.patch` (build suffixes ignored).
bool isVersionLower(String version, String minimum) {
  List<int> parts(String v) =>
      [for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0, 0, 0].take(3).toList();
  final a = parts(version);
  final b = parts(minimum);
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}

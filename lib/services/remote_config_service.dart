import 'package:emiliano_cesare_flutter_template/core/utils/logger.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

typedef AppRemoteConfig = ({String minVersion, bool maintenance});

/// Firebase Remote Config keys: `min_version` (e.g. "1.4.0") and
/// `maintenance_mode` (bool). Add your own keys here.
class RemoteConfigService {
  Future<AppRemoteConfig> load() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kReleaseMode ? const Duration(hours: 1) : const Duration(minutes: 1),
      ),
    );
    await rc.setDefaults(const {'min_version': '0.0.0', 'maintenance_mode': false});
    try {
      await rc.fetchAndActivate();
    } on Object catch (e, s) {
      // Offline: fall back to cached/default values, never block the app.
      talker.handle(e, s, 'Remote config fetch failed');
    }
    return (minVersion: rc.getString('min_version'), maintenance: rc.getBool('maintenance_mode'));
  }
}

@Riverpod(keepAlive: true)
RemoteConfigService remoteConfigService(Ref ref) => RemoteConfigService();

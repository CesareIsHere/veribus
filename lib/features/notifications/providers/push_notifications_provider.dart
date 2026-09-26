import 'dart:async';

import 'package:emiliano_cesare_flutter_template/core/navigation/router.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/repositories/auth/auth_repository_provider.dart';
import 'package:emiliano_cesare_flutter_template/services/push_notifications_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notifications_provider.g.dart';

/// Push notifications, active while a user is signed in: registers the device
/// token with the backend and opens the tapped notification's page.
@Riverpod(keepAlive: true)
Future<void> pushNotifications(Ref ref) async {
  // Only the user id matters: profile edits must not re-register the device.
  final userId = await ref.watch(authProvider.selectAsync((u) => u?.id));
  if (userId == null) return;

  final push = ref.watch(pushNotificationsServiceProvider);
  if (!await push.requestPermission() || !ref.mounted) return;

  void open(String route) => ref.read(routerProvider).go(route);
  Future<void> register(String token) async {
    try {
      await ref.read(authRepositoryProvider).registerPushToken(token);
    } on Object catch (e, s) {
      ExceptionHandler.report(e, s);
    }
  }

  final stopListening = await push.listen(onTap: open);
  if (!ref.mounted) return stopListening();
  final tokenRefresh = push.onTokenRefresh.listen(register);
  ref.onDispose(() {
    stopListening();
    unawaited(tokenRefresh.cancel());
  });

  final route = await push.initialRoute();
  if (route != null && ref.mounted) open(route);
  final token = await push.token();
  if (token != null && ref.mounted) await register(token);
}

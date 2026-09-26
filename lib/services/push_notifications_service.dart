import 'dart:async';

import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notifications_service.g.dart';

/// Called by FCM in a background isolate. Keep it top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// FCM + local notifications (to show messages received in foreground).
/// A message's `data.route` (e.g. "/settings") is the page to open on tap.
class PushNotificationsService {
  static const _channel = AndroidNotificationChannel('default', 'General', importance: Importance.high);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  /// false when the user denied notifications.
  Future<bool> requestPermission() async =>
      (await _messaging.requestPermission()).authorizationStatus != AuthorizationStatus.denied;

  Future<String?> token() =>
      _messaging.getToken(vapidKey: AppConfig.fcmVapidKey.isEmpty ? null : AppConfig.fcmVapidKey);

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Route of the notification that launched the app, if any.
  Future<String?> initialRoute() async => _route((await _messaging.getInitialMessage())?.data);

  /// Shows foreground messages and reports taps. Returns a function that stops listening.
  Future<VoidCallback> listen({required void Function(String route) onTap}) async {
    if (!kIsWeb) {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (r) {
          if (_route({'route': r.payload}) case final route?) onTap(route);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
    final subs = [
      FirebaseMessaging.onMessage.listen(_showForeground),
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        if (_route(m.data) case final route?) onTap(route);
      }),
    ];
    return () {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    };
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null || kIsWeb) return;
    unawaited(
      _local.show(
        id: message.hashCode,
        title: n.title,
        body: n.body,
        payload: _route(message.data),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(_channel.id, _channel.name, importance: Importance.high),
          iOS: const DarwinNotificationDetails(),
        ),
      ),
    );
  }

  /// Only in-app paths are accepted, never external URLs.
  static String? _route(Map<String, dynamic>? data) => switch (data?['route']) {
    final String route when route.startsWith('/') => route,
    _ => null,
  };
}

@Riverpod(keepAlive: true)
PushNotificationsService pushNotificationsService(Ref ref) => PushNotificationsService();

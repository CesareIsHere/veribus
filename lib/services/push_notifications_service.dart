import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/utils/logger.dart';

part 'push_notifications_service.g.dart';

enum PushPermission { granted, denied, notDetermined }

/// Where the app comes from when the user taps a notice: the route in its `link` data.
const defaultNoticeLink = '/trips';

/// Push notifications as the app needs them. Implementations: [FirebasePushService] (Android, iOS) and
/// [MockPushService] (mock backend, tests); the web and iOS have none yet.
abstract interface class IPushService {
  /// Starts what the platform needs and creates the Android channel. False when this build cannot receive push:
  /// the web, or no Firebase configuration (`google-services.json`) in the build.
  Future<bool> init({required String channelName, required String channelDescription});

  Future<PushPermission> permission();

  /// Asks the system (Android 13+, iOS); the answer is final once the user denied twice.
  Future<PushPermission> requestPermission();

  /// This device's FCM token, null when unavailable.
  Future<String?> token();

  Stream<String> get tokenRefreshes;

  /// Routes of notices the user tapped while the app was running.
  Stream<String> get opened;

  /// The route of the notice that launched the app, once.
  Future<String?> launchLink();

  /// Shows a notice on this phone now, without a server: the journey being followed says to get off. False when this
  /// build cannot show notices (the same conditions as [init]) or the user did not allow them.
  Future<bool> showNow({required int id, required String title, required String body, String? link});
}

/// Android channel of the notices: the server names it in every message (`backend/adapters/fcm.ts`).
const noticeChannelId = 'trips';

class FirebasePushService implements IPushService {
  final _local = FlutterLocalNotificationsPlugin();
  final _opened = StreamController<String>.broadcast();
  final _tokens = StreamController<String>.broadcast();
  var _ready = false;
  var _channelName = '';
  var _channelDescription = '';

  @override
  Future<bool> init({required String channelName, required String channelDescription}) async {
    if (_ready) return true;
    // Android only for now: iOS needs the Push capability, an APNs key and GoogleService-Info.plist (see README), and
    // without that file Firebase's iOS SDK aborts instead of throwing.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      // Reads the platform's Firebase file; without it the build simply has no push.
      await Firebase.initializeApp();
    } on Exception catch (e) {
      talker.warning('Push unavailable: $e');
      return false;
    }
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false),
      ),
      onDidReceiveNotificationResponse: (r) => _opened.add(r.payload ?? defaultNoticeLink),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            noticeChannelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
          ),
        );
    // With the app open FCM shows nothing by itself: the notice is drawn here.
    _channelName = channelName;
    _channelDescription = channelDescription;
    FirebaseMessaging.onMessage.listen((m) => unawaited(_show(m)));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _opened.add(_link(m)));
    FirebaseMessaging.instance.onTokenRefresh.listen(_tokens.add);
    _ready = true;
    return true;
  }

  Future<void> _show(RemoteMessage m) async {
    final notification = m.notification;
    if (notification == null) return;
    await _local.show(
      // One notice per followed trip: "in 10 min" replaces "in 15 min".
      id: (m.data['follow_id'] as String?)?.hashCode ?? m.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          noticeChannelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          // Same tag, same notice: "in 10 min" replaces "in 15 min".
          tag: m.data['follow_id'] as String?,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _link(m),
    );
  }

  static String _link(RemoteMessage m) => m.data['link'] as String? ?? defaultNoticeLink;

  PushPermission _of(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };

  @override
  Future<PushPermission> permission() async =>
      _of((await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> requestPermission() async =>
      _of((await FirebaseMessaging.instance.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() => FirebaseMessaging.instance.getToken();

  @override
  // Fed once Firebase is initialized: `FirebaseMessaging.instance` throws before, and the app subscribes at launch.
  Stream<String> get tokenRefreshes => _tokens.stream;

  @override
  Stream<String> get opened => _opened.stream;

  @override
  Future<String?> launchLink() async {
    final m = await FirebaseMessaging.instance.getInitialMessage();
    return m == null ? null : _link(m);
  }

  @override
  Future<bool> showNow({required int id, required String title, required String body, String? link}) async {
    if (!_ready || await permission() != PushPermission.granted) return false;
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          noticeChannelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: link ?? defaultNoticeLink,
    );
    return true;
  }
}

/// Always available and already allowed: the mock backend has no server to push, the UI can still be tried.
class MockPushService implements IPushService {
  @override
  Future<bool> init({required String channelName, required String channelDescription}) async => true;

  @override
  Future<PushPermission> permission() async => PushPermission.granted;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.granted;

  @override
  Future<String?> token() async => 'mock-token';

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  Future<String?> launchLink() async => null;

  @override
  Future<bool> showNow({required int id, required String title, required String body, String? link}) async => true;
}

@Riverpod(keepAlive: true)
IPushService pushService(Ref ref) => AppConfig.backend == Backend.mock ? MockPushService() : FirebasePushService();

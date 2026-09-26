import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Thin Firebase Analytics wrapper: every call is a no-op when the
/// analytics feature is off, so call sites never need a flag check.
abstract final class AnalyticsService {
  /// Automatic screen tracking, plugged into the router.
  static List<NavigatorObserver> get observers =>
      Features.analytics ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)] : const [];

  static Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (Features.analytics) await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  static Future<void> setUserId(String? id) async {
    if (Features.analytics) await FirebaseAnalytics.instance.setUserId(id: id);
  }
}

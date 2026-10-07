import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/navigation/router.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/core/utils/logger.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/repositories/auth/auth_repository_provider.dart';
import 'package:veribus/services/push_notifications_service.dart';

part 'push_notifier.g.dart';

/// Can this device receive the notices of followed trips?
@immutable
class PushState {
  const PushState({this.available, this.permission = PushPermission.notDetermined});

  /// Null until the platform has been asked; false when this build or device has no push at all.
  final bool? available;
  final PushPermission permission;

  bool get ready => available == true && permission == PushPermission.granted;
}

/// Starts push at launch, keeps this device's token linked to the signed-in user (with the language of the app),
/// and opens the page of a notice the user taps.
@Riverpod(keepAlive: true)
class PushNotifier extends _$PushNotifier {
  IPushService get _service => ref.read(pushServiceProvider);

  /// The token registered for the current user, to take it back at sign-out.
  String? _registered;

  @override
  PushState build() {
    final service = ref.watch(pushServiceProvider);
    final subscriptions = [
      service.tokenRefreshes.listen((t) => unawaited(_register(token: t))),
      service.opened.listen(_open),
    ];
    ref
      ..onDispose(() {
        for (final s in subscriptions) {
          unawaited(s.cancel());
        }
      })
      // Signing in on a device that already has the permission, or switching language, relinks the token.
      ..listen(authProvider, (previous, next) {
        if (next.value != null && next.value?.id != previous?.value?.id) unawaited(_register());
      })
      ..listen(localeProvider, (_, _) => unawaited(_register()));
    unawaited(_start());
    return const PushState();
  }

  Future<void> _start() async {
    final names = _l10n();
    final available = await _service.init(
      channelName: names.noticeChannelName,
      channelDescription: names.noticeChannelDescription,
    );
    final permission = available ? await _service.permission() : PushPermission.denied;
    state = PushState(available: available, permission: permission);
    if (state.ready) await _register();
    final link = available ? await _service.launchLink() : null;
    if (link != null) _open(link);
  }

  /// Asks for the permission (once the user wants to follow a trip) and links this device. True when granted.
  Future<bool> enable() async {
    if (state.available != true) return false;
    final permission = await _service.requestPermission();
    state = PushState(available: true, permission: permission);
    if (state.ready) await _register();
    return state.ready;
  }

  /// At sign-out: this device stops getting the user's notices.
  Future<void> unregister() async {
    try {
      final token = _registered ?? (state.ready ? await _service.token() : null);
      _registered = null;
      if (token == null) return;
      await ref.read(authRepositoryProvider).unregisterPushToken(token);
    } on Object catch (e, s) {
      talker.handle(e, s); // signing out must not fail for this
    }
  }

  Future<void> _register({String? token}) async {
    if (!state.ready || ref.read(authProvider).value == null) return;
    try {
      final t = token ?? await _service.token();
      if (t == null) return;
      await ref.read(authRepositoryProvider).registerPushToken(t, locale: _l10n().localeName);
      _registered = t;
    } on Object catch (e, s) {
      talker.handle(e, s); // a failed link is retried at the next launch or token refresh
    }
  }

  void _open(String link) {
    // `link` comes from our own server: still, only paths inside the app.
    if (link.startsWith('/') && !link.startsWith('//')) unawaited(ref.read(routerProvider).push(link));
  }

  /// The app's texts in the language in use; English when the phone speaks one the app has not got.
  AppLocalizations _l10n() {
    final wanted = ref.read(localeProvider) ?? PlatformDispatcher.instance.locale;
    final supported = AppLocalizations.supportedLocales.any((l) => l.languageCode == wanted.languageCode);
    return lookupAppLocalizations(supported ? wanted : const Locale('en'));
  }
}

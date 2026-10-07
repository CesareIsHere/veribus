// The providers are overridden at the root of each test: nothing scoped to declare.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/features/notifications/providers/push_notifier.dart';
import 'package:veribus/services/push_notifications_service.dart';

class _Service extends MockPushService {
  _Service({this.available = true, this.granted = PushPermission.granted});

  final bool available;
  PushPermission granted;
  int asked = 0;
  final List<String> names = [];

  @override
  Future<bool> init({required String channelName, required String channelDescription}) async {
    names.add(channelName);
    return available;
  }

  @override
  Future<PushPermission> permission() async => granted;

  @override
  Future<PushPermission> requestPermission() async {
    asked++;
    return granted = PushPermission.granted;
  }
}

/// A container with push started, and time for its async start-up to finish.
Future<ProviderContainer> _started(_Service service, {Locale? locale}) async {
  final c = ProviderContainer(
    overrides: [
      pushServiceProvider.overrideWithValue(service),
      localeProvider.overrideWithBuild((ref, notifier) => locale),
    ],
  );
  addTearDown(c.dispose);
  c.listen(pushProvider, (_, _) {});
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return c;
}

void main() {
  test('starts at launch: a granted permission means notices can arrive', () async {
    final service = _Service();
    final c = await _started(service);
    expect(c.read(pushProvider).ready, isTrue);
  });

  test('a phone in a language the app has not got still starts (the channel is named in English)', () async {
    final service = _Service();
    final c = await _started(service, locale: const Locale('fr'));
    expect(c.read(pushProvider).ready, isTrue);
    expect(service.names.single, 'Followed trips');
  });

  test('the channel is named in the language of the app', () async {
    final service = _Service();
    await _started(service, locale: const Locale('it'));
    expect(service.names.single, 'Corse seguite');
  });

  test('a build without push is reported as such and never asks the system', () async {
    final service = _Service(available: false);
    final c = await _started(service);
    expect(c.read(pushProvider).available, isFalse);
    expect(await c.read(pushProvider.notifier).enable(), isFalse);
    expect(service.asked, 0);
  });

  test('the permission is asked on request, once the user follows a trip', () async {
    final service = _Service(granted: PushPermission.notDetermined);
    final c = await _started(service);
    expect(c.read(pushProvider).ready, isFalse);
    expect(await c.read(pushProvider.notifier).enable(), isTrue);
    expect(c.read(pushProvider).ready, isTrue);
    expect(service.asked, 1);
  });
}

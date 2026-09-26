import 'dart:async';

import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/biometric_lock/providers/biometric_lock_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Covers the app with a lock screen at start and whenever it returns from
/// background, while the lock is enabled and a user is signed in.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _listener;
  bool _locked = true;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    // Cold start is locked (the session may still be loading). A fresh
    // sign-in or just enabling the lock must not lock the user out.
    ref
      ..listenManual(authProvider, (prev, next) {
        final freshSignIn = prev != null && prev.hasValue && prev.value == null && next.value != null;
        if (freshSignIn) {
          setState(() => _locked = false);
        } else {
          unawaited(_unlock());
        }
      })
      ..listenManual(biometricLockProvider, (_, enabled) {
        if (enabled) setState(() => _locked = false);
      });
    _listener = AppLifecycleListener(
      // The system biometric prompt doesn't hide the app, so this won't loop.
      onHide: () => setState(() => _locked = _active),
      onShow: _unlock,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  bool get _active => ref.read(biometricLockProvider) && ref.read(authProvider).value != null;

  Future<void> _unlock() async {
    if (!_active || !_locked || _authenticating) return;
    _authenticating = true;
    try {
      final ok = await ref.read(biometricLockProvider.notifier).authenticate(context.l10n.unlockReason);
      if (ok && mounted) setState(() => _locked = false);
    } on Object {
      // Stay locked; the user can retry with the button.
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(biometricLockProvider)
      ..watch(authProvider);
    if (!_active || !_locked) return widget.child;
    return Scaffold(
      body: MessageView(
        icon: Icons.lock_outline,
        title: context.l10n.appLocked,
        action: FilledButton.icon(
          onPressed: _unlock,
          icon: const Icon(Icons.fingerprint),
          label: Text(context.l10n.unlock),
        ),
      ),
    );
  }
}

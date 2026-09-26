import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home placeholder, used when the demo is off (`FEATURE_DEMO=false`).
/// Replace it with your app's first screen.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.home)),
      body: MessageView(
        icon: Icons.rocket_launch_outlined,
        title: context.l10n.homeGreeting(user?.displayName ?? ''),
        description: context.l10n.homePlaceholder,
      ),
    );
  }
}

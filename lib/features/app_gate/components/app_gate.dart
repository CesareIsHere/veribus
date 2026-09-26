import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/package_info_provider.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/app_gate/providers/app_gate_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blocks the app when Remote Config asks for an update or maintenance.
/// While loading or on error the app stays usable.
class AppGate extends ConsumerWidget {
  const AppGate({required this.child, super.key});

  final Widget child;

  Future<void> _openStore(String? packageName) => launchUrl(
    Uri.parse(
      defaultTargetPlatform == TargetPlatform.iOS
          ? 'https://apps.apple.com/app/id${AppConfig.appStoreId}'
          : 'https://play.google.com/store/apps/details?id=$packageName',
    ),
    mode: LaunchMode.externalApplication,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (ref.watch(appGateProvider).value) {
      AppGateStatus.updateRequired => Scaffold(
        body: MessageView(
          icon: Icons.system_update,
          title: l10n.updateRequired,
          action: kIsWeb
              ? null
              : FilledButton(
                  onPressed: () => _openStore(ref.read(packageInfoProvider).value?.packageName),
                  child: Text(l10n.update),
                ),
        ),
      ),
      AppGateStatus.maintenance => Scaffold(
        body: MessageView(icon: Icons.engineering_outlined, title: l10n.maintenance),
      ),
      _ => child,
    };
  }
}

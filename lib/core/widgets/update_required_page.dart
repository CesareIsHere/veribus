import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';

/// True when [version] (e.g. "1.2.0") is below [minimum]. Missing parts count as 0.
bool isOlderVersion(String version, String minimum) {
  List<int> parts(String v) => [for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0];
  final a = parts(version);
  final b = parts(minimum);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}

/// Shown instead of the app below `min_app_version` (RNF-08).
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({required this.packageName, super.key});

  final String packageName;

  @override
  Widget build(BuildContext context) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final store = ios
        ? 'https://apps.apple.com/app/id${AppConfig.appStoreId}'
        : 'https://play.google.com/store/apps/details?id=$packageName';
    return Scaffold(
      body: MessageView(
        icon: Icons.system_update,
        title: context.l10n.updateRequired,
        action: kIsWeb
            ? null
            : FilledButton(onPressed: () => launchUrl(Uri.parse(store)), child: Text(context.l10n.update)),
      ),
    );
  }
}

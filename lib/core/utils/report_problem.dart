import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/providers/package_info_provider.dart';

bool get canReportProblem => Features.feedback && AppConfig.supportEmail.isNotEmpty;

/// "Segnala un problema": a prefilled email with the app version and the open stop or line (RF-71).
Future<void> reportProblem(WidgetRef ref, {String? about}) {
  final version = ref.read(packageInfoProvider).value?.version ?? '';
  final subject = '${AppConfig.appName} $version${about == null ? '' : ' · $about'}';
  return launchUrl(
    Uri(scheme: 'mailto', path: AppConfig.supportEmail, query: 'subject=${Uri.encodeComponent(subject)}'),
  );
}

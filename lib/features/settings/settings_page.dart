import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/locale_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/package_info_provider.dart';
import 'package:emiliano_cesare_flutter_template/core/providers/theme_mode_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/dialogs/confirm_dialog.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/section_header.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/biometric_lock/providers/biometric_lock_notifier.dart'; // feature:biometric_lock
import 'package:emiliano_cesare_flutter_template/features/payments/paywall_page.dart'; // feature:payments
import 'package:emiliano_cesare_flutter_template/features/payments/providers/payments_provider.dart'; // feature:payments
import 'package:emiliano_cesare_flutter_template/features/settings/components/user_avatar.dart';
import 'package:emiliano_cesare_flutter_template/features/settings/profile_page.dart';
import 'package:emiliano_cesare_flutter_template/l10n/gen/app_localizations.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart'; // feature:app_review
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const route = '/settings';
  static const logsRoute = '/settings/logs';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).value;
    final version = ref.watch(packageInfoProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final themeLabels = {
      ThemeMode.system: l10n.systemDefault,
      ThemeMode.light: l10n.themeLight,
      ThemeMode.dark: l10n.themeDark,
    };
    final languageLabels = <String?, String>{
      null: l10n.systemDefault,
      for (final l in AppLocalizations.supportedLocales) l.languageCode: _languageName(l.languageCode),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: context.listPadding(),
        children: [
          SectionHeader(l10n.account),
          ListTile(
            leading: UserAvatar(user: user),
            title: Text(user?.displayName ?? l10n.profile),
            subtitle: Text(user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(ProfilePage.route),
          ),
          // feature:payments:start
          if (Features.payments)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(l10n.premium),
              subtitle: Text(ref.watch(isPremiumProvider) ? l10n.premiumActiveShort : l10n.premiumUpsell),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(PaywallPage.route),
            ),
          // feature:payments:end
          ListTile(leading: const Icon(Icons.logout), title: Text(l10n.signOut), onTap: () => _signOut(context, ref)),
          SectionHeader(l10n.appearance),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.theme),
            subtitle: Text(themeLabels[themeMode]!),
            onTap: () async {
              final mode = await showChoiceDialog(
                context,
                title: l10n.theme,
                selected: themeMode,
                options: themeLabels,
              );
              if (mode != null) await ref.read(themeModeProvider.notifier).set(mode);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(languageLabels[locale?.languageCode]!),
            onTap: () async {
              // A sentinel distinguishes "System" (null value) from "dismissed" (null result).
              final code = await showChoiceDialog<String>(
                context,
                title: l10n.language,
                selected: locale?.languageCode ?? '',
                options: {for (final e in languageLabels.entries) e.key ?? '': e.value},
              );
              if (code != null) await ref.read(localeProvider.notifier).set(code.isEmpty ? null : Locale(code));
            },
          ),
          // feature:biometric_lock:start
          if (Features.biometricLock && (ref.watch(biometricSupportedProvider).value ?? false)) ...[
            SectionHeader(l10n.security),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.biometricLock),
              subtitle: Text(l10n.biometricLockDescription),
              value: ref.watch(biometricLockProvider),
              onChanged: (v) => ExceptionHandler.handle(
                context,
                () => ref.read(biometricLockProvider.notifier).setEnabled(enabled: v, reason: l10n.unlockReason),
              ),
            ),
          ],
          // feature:biometric_lock:end
          SectionHeader(l10n.support),
          // feature:feedback:start
          if (Features.feedback && AppConfig.supportEmail.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: Text(l10n.sendFeedback),
              onTap: () => launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: AppConfig.supportEmail,
                  query: 'subject=${Uri.encodeComponent('${AppConfig.appName} feedback (${version?.version})')}',
                ),
              ),
            ),
          // feature:feedback:end
          // feature:app_review:start
          if (Features.appReview)
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l10n.rateApp),
              onTap: () => InAppReview.instance.openStoreListing(appStoreId: AppConfig.appStoreId),
            ),
          // feature:app_review:end
          if (AppConfig.termsUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.terms),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl)),
            ),
          if (AppConfig.privacyUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.privacy),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl)),
            ),
          SectionHeader(l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: Text('${version?.version ?? ''} (${version?.buildNumber ?? ''}) · ${AppConfig.stage}'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l10n.licenses),
            onTap: () => showLicensePage(context: context, applicationVersion: version?.version),
          ),
          if (!AppConfig.isProd)
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.logs),
              onTap: () => context.push(logsRoute),
            ),
          const SizedBox(height: Spacing.l),
        ],
      ),
    );
  }

  static String _languageName(String code) => switch (code) {
    'it' => 'Italiano',
    'en' => 'English',
    _ => code.toUpperCase(),
  };

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOut,
      message: l10n.signOutConfirm,
      confirmLabel: l10n.signOut,
    );
    if (confirmed && context.mounted) await ExceptionHandler.handle(context, ref.read(authProvider.notifier).signOut);
  }
}

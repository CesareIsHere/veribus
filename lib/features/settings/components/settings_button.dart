import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/settings/settings_page.dart';
import 'package:veribus/models/user/user_model.dart';
import 'package:veribus/styles/app_spacing.dart';

/// The way into Settings (profile, language, theme, app updates, support): the user's initials, top right, on every
/// page that has a search bar.
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  /// "EC" for "Emiliano Cesare", "E" for a single name or an email address.
  static String initialsOf(UserModel? user) {
    final name = user?.displayName?.trim() ?? '';
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final source = words.isNotEmpty ? words.take(2).map((w) => w[0]).join() : (user?.email.trim() ?? '');
    return source.isEmpty ? '?' : source.substring(0, source.length < 2 ? source.length : 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final initials = initialsOf(ref.watch(authProvider).value);
    return IconButton(
      tooltip: context.l10n.exploreProfile,
      icon: CircleAvatar(
        radius: Spacing.l,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: Text(
          initials,
          // The color is the avatar's own: the theme's label color is for text on a surface, not on the primary.
          style: context.textTheme.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      onPressed: () => context.push(SettingsPage.route),
    );
  }
}

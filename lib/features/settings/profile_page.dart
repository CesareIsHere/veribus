import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veribus/core/providers/auth_notifier.dart';
import 'package:veribus/core/utils/exception_handler.dart';
import 'package:veribus/core/utils/validators.dart';
import 'package:veribus/core/widgets/buttons/loading_button.dart';
import 'package:veribus/core/widgets/dialogs/confirm_dialog.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/settings/components/user_avatar.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Edit name/avatar and delete the account (required by App Store and Play).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  static const route = '/settings/profile';

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: ref.read(authProvider).value?.displayName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    await ExceptionHandler.handle(
      context,
      () => ref.read(authProvider.notifier).updateProfile(avatar: bytes),
      successMessage: context.l10n.saved,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ExceptionHandler.handle(
      context,
      () => ref.read(authProvider.notifier).updateProfile(displayName: _name.text.trim()),
      successMessage: context.l10n.saved,
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (confirmed && mounted) await ExceptionHandler.handle(context, ref.read(authProvider.notifier).deleteAccount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: context.pagePadding(maxWidth: ContentWidth.form, top: Spacing.xl),
        children: [
          Center(
            child: Badge(
              backgroundColor: Colors.transparent,
              offset: const Offset(-Spacing.xl, -Spacing.xl),
              alignment: AlignmentDirectional.bottomEnd,
              label: IconButton.filledTonal(
                tooltip: l10n.changePhoto,
                onPressed: _pickAvatar,
                icon: const Icon(Icons.photo_camera_outlined),
              ),
              child: UserAvatar(user: user, radius: 48),
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: Validators.required(l10n),
              decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.person_outline)),
            ),
          ),
          const SizedBox(height: Spacing.l),
          TextFormField(
            initialValue: user?.email,
            enabled: false,
            decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.mail_outline)),
          ),
          const SizedBox(height: Spacing.xl),
          LoadingButton(onPressed: _save, label: l10n.save),
          const SizedBox(height: Spacing.xxxl),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.l, Spacing.s, Spacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.deleteAccount, style: context.textTheme.titleMedium),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.deleteAccountDescription,
                    style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: context.colors.error),
                      onPressed: _delete,
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

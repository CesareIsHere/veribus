import 'package:emiliano_cesare_flutter_template/models/user/user_model.dart';
import 'package:flutter/material.dart';

/// Photo if available, otherwise the initial of name/email.
class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.user, this.radius = 20, super.key});

  final UserModel? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = user?.photoUrl;
    final label = user?.displayName ?? user?.email ?? '?';
    return CircleAvatar(
      radius: radius,
      foregroundImage: photo == null ? null : NetworkImage(photo),
      child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase()),
    );
  }
}

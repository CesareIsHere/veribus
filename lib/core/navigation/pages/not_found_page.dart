import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/home/home_page.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: MessageView(
        icon: Icons.explore_off_outlined,
        title: context.l10n.pageNotFound,
        action: FilledButton(onPressed: () => context.go(HomePage.route), child: Text(context.l10n.goHome)),
      ),
    );
  }
}

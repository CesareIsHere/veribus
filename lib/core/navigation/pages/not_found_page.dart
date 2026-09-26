import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

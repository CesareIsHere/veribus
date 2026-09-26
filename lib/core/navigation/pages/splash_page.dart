import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shown while the session is being restored (router redirects away after).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const route = '/splash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 96),
            const SizedBox(height: Spacing.xxl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/onboarding/providers/onboarding_notifier.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown once before login. Completing it triggers the router redirect.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  static const route = '/onboarding';

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() => ref.read(onboardingProvider.notifier).complete();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      (Icons.account_balance_wallet_outlined, l10n.onboarding1Title, l10n.onboarding1Body),
      (Icons.insights_outlined, l10n.onboarding2Title, l10n.onboarding2Body),
      (Icons.verified_user_outlined, l10n.onboarding3Title, l10n.onboarding3Body),
    ];
    final isLast = _page == slides.length - 1;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _done, child: Text(l10n.skip)),
          const SizedBox(width: Spacing.s),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ContentWidth.form),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      for (final (icon, title, body) in slides)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 56,
                                backgroundColor: context.colors.primaryContainer,
                                child: Icon(icon, size: 56, color: context.colors.onPrimaryContainer),
                              ),
                              const SizedBox(height: Spacing.xxl),
                              Text(title, style: context.textTheme.headlineSmall, textAlign: TextAlign.center),
                              const SizedBox(height: Spacing.m),
                              Text(
                                body,
                                style: context.textTheme.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _PageDots(count: slides.length, current: _page),
                Padding(
                  padding: EdgeInsets.all(context.pageMargin),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLast
                          ? _done
                          : () => _controller.nextPage(duration: Durations.medium2, curve: Easing.standard),
                      child: Text(isLast ? l10n.getStarted : l10n.next),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: Spacing.s,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Durations.short4,
            width: i == current ? Spacing.xl : Spacing.s,
            height: Spacing.s,
            decoration: BoxDecoration(
              color: i == current ? context.colors.primary : context.colors.outlineVariant,
              borderRadius: BorderRadius.circular(Spacing.xs),
            ),
          ),
      ],
    );
  }
}

import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/buttons/loading_button.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/payments/providers/payments_provider.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Benefits + the plans of the current RevenueCat offering + one CTA.
class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  static const route = '/paywall';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offering = ref.watch(currentOfferingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premium)),
      body: switch (offering) {
        _ when !ref.watch(paymentsAvailableProvider) => MessageView(icon: Icons.block, title: l10n.errorNotSupported),
        _ when ref.watch(isPremiumProvider) => MessageView(
          icon: Icons.workspace_premium,
          title: l10n.premiumActive,
          action: FilledButton(onPressed: () => context.pop(), child: Text(l10n.close)),
        ),
        AsyncValue(:final error?) => MessageView.error(
          context,
          error,
          onRetry: () => ref.invalidate(currentOfferingProvider),
        ),
        AsyncValue(value: final Offering offering) when offering.availablePackages.isNotEmpty => _Plans(offering),
        AsyncValue(hasValue: true) => MessageView(icon: Icons.storefront, title: l10n.noOffering),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Plans extends ConsumerStatefulWidget {
  const _Plans(this.offering);

  final Offering offering;

  @override
  ConsumerState<_Plans> createState() => _PlansState();
}

class _PlansState extends ConsumerState<_Plans> {
  late Package _selected = widget.offering.availablePackages.first;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final payments = ref.read(paymentsProvider.notifier);

    return ListView(
      padding: context.pagePadding(maxWidth: ContentWidth.form, top: Spacing.xl),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: context.colors.primaryContainer,
            child: Icon(Icons.workspace_premium, size: 40, color: context.colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: Spacing.l),
        Text(l10n.premiumPitch, style: context.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: Spacing.xl),
        for (final benefit in [l10n.premiumBenefit1, l10n.premiumBenefit2, l10n.premiumBenefit3])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle, color: context.colors.primary),
            title: Text(benefit),
          ),
        const SizedBox(height: Spacing.l),
        RadioGroup<Package>(
          groupValue: _selected,
          onChanged: (p) => setState(() => _selected = p ?? _selected),
          child: Column(
            spacing: Spacing.s,
            children: [
              for (final package in widget.offering.availablePackages)
                Card.outlined(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: RadioListTile<Package>(
                    value: package,
                    title: Text(package.storeProduct.title),
                    subtitle: Text(package.storeProduct.priceString),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),
        LoadingButton(
          onPressed: () => ExceptionHandler.handle(context, () => payments.purchase(_selected)),
          label: l10n.subscribe,
        ),
        const SizedBox(height: Spacing.s),
        TextButton(
          onPressed: () => ExceptionHandler.handle(context, payments.restore),
          child: Text(l10n.restorePurchases),
        ),
      ],
    );
  }
}

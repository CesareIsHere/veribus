import 'package:emiliano_cesare_flutter_template/core/providers/auth_notifier.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/dashboard/components/dashboard_cards.dart';
import 'package:emiliano_cesare_flutter_template/features/dashboard/providers/dashboard_providers.dart';
import 'package:emiliano_cesare_flutter_template/features/home/home_page.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/transaction_form_page.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/month_summary.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Demo home: the selected month at a glance.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const String route = HomePage.route;

  static final MonthSummary _placeholder = MonthSummary.from([
    for (final (i, c) in [
      TransactionCategory.salary,
      ...TransactionCategory.of(TransactionType.expense).take(4),
    ].indexed)
      TransactionModel(id: '$i', title: 'Placeholder', amount: 10000 * (5 - i), category: c, date: DateTime(2000)),
  ], days: 30);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).value;
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthSummaryProvider(month));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeGreeting(user?.displayName ?? ''))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(TransactionFormPage.newRoute),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(monthSummaryProvider(month).future),
        child: ListView(
          padding: context.pagePadding(maxWidth: ContentWidth.wide, top: Spacing.s, bottom: Spacing.xxxl + Spacing.xxl),
          children: [
            const MonthSelector(),
            const SizedBox(height: Spacing.l),
            switch (summary) {
              AsyncValue(:final error?, hasValue: false) => MessageView.error(
                context,
                error,
                onRetry: () => ref.invalidate(monthSummaryProvider(month)),
              ),
              AsyncValue(:final value?) when value.isEmpty => MessageView(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.noTransactionsMonth,
                description: l10n.noTransactionsDescription,
              ),
              AsyncValue(:final value) => Skeletonizer(enabled: value == null, child: _Cards(value ?? _placeholder)),
            },
          ],
        ),
      ),
    );
  }
}

/// One column on compact/medium, two from expanded up.
class _Cards extends StatelessWidget {
  const _Cards(this.summary);

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final left = [BalanceCard(summary), CategoryBreakdownCard(summary)];
    final right = [InsightsCard(summary), RecentTransactionsCard(summary)];
    Widget column(List<Widget> cards) =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: Spacing.l, children: cards);

    if (context.windowSize.index < WindowSize.expanded.index) return column([...left, ...right]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xl,
      children: [
        Expanded(child: column(left)),
        Expanded(child: column(right)),
      ],
    );
  }
}

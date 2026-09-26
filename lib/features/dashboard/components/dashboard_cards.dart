import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/money.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/dashboard/providers/dashboard_providers.dart';
import 'package:emiliano_cesare_flutter_template/features/payments/paywall_page.dart'; // feature:payments
import 'package:emiliano_cesare_flutter_template/features/payments/providers/payments_provider.dart'; // feature:payments
import 'package:emiliano_cesare_flutter_template/features/transactions/components/transaction_ui.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/transaction_form_page.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/transactions_page.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/month_summary.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// ‹ September 2026 › with the future disabled.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final label = toBeginningOfSentenceCase(DateFormat.yMMMM().format(month));
    return Row(
      children: [
        IconButton(
          tooltip: context.l10n.previousMonth,
          onPressed: notifier.previous,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(label, style: context.textTheme.titleMedium, textAlign: TextAlign.center),
        ),
        IconButton(
          tooltip: context.l10n.nextMonth,
          onPressed: notifier.canGoNext ? notifier.next : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Hero card: month balance, income and expenses.
class BalanceCard extends StatelessWidget {
  const BalanceCard(this.summary, {super.key});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onContainer = context.colors.onPrimaryContainer;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.monthBalance, style: context.textTheme.labelLarge?.copyWith(color: onContainer)),
            const SizedBox(height: Spacing.xs),
            Text(Money.format(summary.balance), style: context.textTheme.displaySmall?.copyWith(color: onContainer)),
            const SizedBox(height: Spacing.xl),
            Row(
              spacing: Spacing.l,
              children: [
                Expanded(
                  child: _Figure(icon: Icons.arrow_downward, label: l10n.income, cents: summary.income),
                ),
                Expanded(
                  child: _Figure(icon: Icons.arrow_upward, label: l10n.expenses, cents: summary.expenses),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.icon, required this.label, required this.cents});

  final IconData icon;
  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onPrimaryContainer;
    return Row(
      spacing: Spacing.s,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.primary,
          child: Icon(icon, size: 18),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textTheme.labelMedium?.copyWith(color: color)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(Money.format(cents), style: context.textTheme.titleSmall?.copyWith(color: color)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Outlined card with a title row and optional trailing action.
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Spacing.l, Spacing.l, action == null ? Spacing.l : Spacing.s, Spacing.s),
            child: Row(
              children: [
                Expanded(child: Text(title, style: context.textTheme.titleMedium)),
                ?action,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard(this.summary, {super.key});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = summary.expensesByCategory.take(5);
    return _DashboardCard(
      title: l10n.spendingByCategory,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, Spacing.l),
        child: top.isEmpty
            ? Text(l10n.noExpenses, style: context.textTheme.bodyMedium)
            : Column(
                spacing: Spacing.l,
                children: [
                  for (final (:category, :amount) in top)
                    Row(
                      spacing: Spacing.l,
                      children: [
                        Icon(category.icon, color: context.colors.onSurfaceVariant),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: Spacing.s,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(category.label(l10n), style: context.textTheme.bodyMedium)),
                                  Text(Money.format(amount), style: context.textTheme.labelLarge),
                                ],
                              ),
                              LinearProgressIndicator(
                                value: summary.expenses == 0 ? 0 : amount / summary.expenses,
                                borderRadius: BorderRadius.circular(Spacing.xs),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

/// Savings rate and daily average. Behind the paywall when payments are on.
class InsightsCard extends ConsumerWidget {
  const InsightsCard(this.summary, {super.key});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // feature:payments:start
    if (Features.payments && !ref.watch(isPremiumProvider)) {
      return _DashboardCard(
        title: l10n.insights,
        child: ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.insightsLocked),
          trailing: FilledButton.tonal(onPressed: () => context.push(PaywallPage.route), child: Text(l10n.unlock)),
        ),
      );
    }
    // feature:payments:end
    final rate = summary.savingsRate;
    return _DashboardCard(
      title: l10n.insights,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: Text(l10n.savingsRate),
            trailing: Text(
              rate == null ? '—' : NumberFormat.percentPattern().format(rate),
              style: context.textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l10n.averageDailyExpense),
            trailing: Text(Money.format(summary.averageDailyExpense), style: context.textTheme.titleMedium),
          ),
          const SizedBox(height: Spacing.s),
        ],
      ),
    );
  }
}

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard(this.summary, {super.key});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DashboardCard(
      title: l10n.recentTransactions,
      action: TextButton(onPressed: () => context.go(TransactionsPage.route), child: Text(l10n.seeAll)),
      child: summary.recent.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.l),
              child: Text(l10n.noTransactions, style: context.textTheme.bodyMedium),
            )
          : Column(
              children: [
                for (final t in summary.recent)
                  TransactionTile(
                    transaction: t,
                    showDate: true,
                    onTap: () => context.push(TransactionFormPage.editRoute(t.id)),
                  ),
                const SizedBox(height: Spacing.s),
              ],
            ),
    );
  }
}

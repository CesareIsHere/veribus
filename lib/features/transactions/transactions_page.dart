import 'dart:async';

import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/section_header.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/app_failure_extensions.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/components/transaction_ui.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/providers/transactions_providers.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/transaction_form_page.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Infinite list grouped by day, with filters, pull-to-refresh and
/// swipe-to-delete with undo.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  static const route = '/transactions';

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  TransactionType? _filter;

  static final List<TransactionModel> _placeholders = List.generate(
    10,
    (i) => TransactionModel(
      id: '$i',
      title: 'Placeholder title',
      amount: 1000,
      category: TransactionCategory.groceries,
      date: DateTime(2000),
    ),
  );

  Future<void> _delete(TransactionModel t) async {
    final l10n = context.l10n;
    final controller = ref.read(transactionsControllerProvider.notifier);
    ref.read(transactionsProvider(_filter).notifier).removeLocally(t.id);
    context.showSnackBar(
      l10n.transactionDeleted,
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () => controller.save(t.copyWith(id: '')).ignore(),
      ),
    );
    await ExceptionHandler.handle(context, () => controller.delete(t));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = transactionsProvider(_filter);
    final transactions = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactions)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(TransactionFormPage.newRoute),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Aligned with the rows' content (list inset + ListTile's 16dp).
            padding: EdgeInsets.symmetric(horizontal: context.listPadding().left + Spacing.l, vertical: Spacing.s),
            child: Row(
              spacing: Spacing.s,
              children: [
                for (final (type, label) in [
                  (null, l10n.all),
                  (TransactionType.income, l10n.income),
                  (TransactionType.expense, l10n.expenses),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: switch (transactions) {
                AsyncValue(:final error?, hasValue: false) => ListView(
                  children: [MessageView.error(context, error, onRetry: () => ref.invalidate(provider))],
                ),
                AsyncValue(:final value?) when value.items.isEmpty => ListView(
                  children: [
                    MessageView(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.noTransactions,
                      description: l10n.noTransactionsDescription,
                    ),
                  ],
                ),
                AsyncValue(:final value) => Skeletonizer(
                  enabled: value == null,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 300) unawaited(ref.read(provider.notifier).loadMore());
                      return false;
                    },
                    child: _GroupedList(
                      items: value?.items ?? _placeholders,
                      state: value,
                      onDelete: _delete,
                      onRetry: ref.read(provider.notifier).retryLoadMore,
                    ),
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rows with a subheader each time the day changes.
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.items, required this.state, required this.onDelete, required this.onRetry});

  final List<TransactionModel> items;
  final TransactionsState? state;
  final ValueChanged<TransactionModel> onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final rows = <Object>[];
    for (final (i, t) in items.indexed) {
      if (i == 0 || !DateUtils.isSameDay(items[i - 1].date, t.date)) rows.add(t.date);
      rows.add(t);
    }

    return ListView.builder(
      // Room for the extended FAB over the last row.
      padding: context.listPadding(bottom: Spacing.xxxl + Spacing.xxl),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == rows.length) return _Footer(state: state, onRetry: onRetry);
        return switch (rows[i]) {
          final DateTime day => SectionHeader(_dayLabel(context, day)),
          final TransactionModel t => Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: ColoredBox(
              color: context.colors.errorContainer,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: Spacing.xl),
                  child: Icon(Icons.delete_outline, color: context.colors.onErrorContainer),
                ),
              ),
            ),
            onDismissed: (_) => onDelete(t),
            child: TransactionTile(transaction: t, onTap: () => context.push(TransactionFormPage.editRoute(t.id))),
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  static String _dayLabel(BuildContext context, DateTime day) {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateUtils.dateOnly(day);
    if (date == today) return context.l10n.today;
    if (date == today.subtract(const Duration(days: 1))) return context.l10n.yesterday;
    return MaterialLocalizations.of(context).formatMediumDate(day);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final TransactionsState? state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TransactionsState(loadingMore: true) => const Padding(
        padding: EdgeInsets.all(Spacing.l),
        child: Center(child: CircularProgressIndicator()),
      ),
      TransactionsState(:final loadMoreError?) => ListTile(
        leading: Icon(Icons.error_outline, color: context.colors.error),
        title: Text(AppFailure.from(loadMoreError).message(context.l10n)),
        trailing: TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

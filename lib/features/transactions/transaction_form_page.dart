import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/money.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/validators.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/dialogs/confirm_dialog.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/components/transaction_ui.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/providers/transactions_providers.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Create / edit a transaction. An M3 full-screen dialog: close on the left,
/// save on the right, delete at the bottom when editing.
class TransactionFormPage extends ConsumerWidget {
  const TransactionFormPage({this.id, super.key});

  static const newRoute = '/transactions/new';
  static String editRoute(String id) => '/transactions/$id';

  /// Null to create a new transaction.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    if (id == null) return const _TransactionForm();
    return switch (ref.watch(transactionProvider(id))) {
      AsyncValue(value: final TransactionModel t) => _TransactionForm(initial: t),
      AsyncValue(:final error?) => Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: MessageView.error(context, error, onRetry: () => ref.invalidate(transactionProvider(id))),
      ),
      _ => Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({this.initial});

  final TransactionModel? initial;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.initial == null ? '' : NumberFormat.decimalPattern().format(widget.initial!.amount / 100),
  );
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _note = TextEditingController(text: widget.initial?.note);
  late TransactionCategory _category = widget.initial?.category ?? TransactionCategory.groceries;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    for (final c in [_amount, _title, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setType(TransactionType type) {
    if (type != _category.type) setState(() => _category = TransactionCategory.of(type).first);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = DateUtils.dateOnly(picked).add(Duration(hours: _date.hour)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final transaction = TransactionModel(
      id: widget.initial?.id ?? '',
      title: _title.text.trim(),
      amount: Money.parse(_amount.text)!,
      category: _category,
      date: _date,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    final saved = await ExceptionHandler.handle(
      context,
      () => ref.read(transactionsControllerProvider.notifier).save(transaction),
      successMessage: context.l10n.saved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteTransaction,
      message: l10n.deleteTransactionConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await ExceptionHandler.handle(
      context,
      () => ref.read(transactionsControllerProvider.notifier).delete(widget.initial!),
      successMessage: l10n.transactionDeleted,
    );
    if (deleted && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.simpleCurrency(name: AppConfig.currency).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(_isEdit ? l10n.editTransaction : l10n.newTransaction),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
          const SizedBox(width: Spacing.s),
        ],
        bottom: _saving
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: context.pagePadding(maxWidth: ContentWidth.form, top: Spacing.xl),
          children: [
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  icon: const Icon(Icons.arrow_upward),
                  label: Text(TransactionType.expense.label(l10n)),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  icon: const Icon(Icons.arrow_downward),
                  label: Text(TransactionType.income.label(l10n)),
                ),
              ],
              selected: {_category.type},
              onSelectionChanged: (s) => _setType(s.first),
            ),
            const SizedBox(height: Spacing.xl),
            TextFormField(
              controller: _amount,
              autofocus: !_isEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: context.textTheme.headlineSmall,
              validator: (v) => Money.parse(v ?? '') == null ? l10n.validationAmount : null,
              decoration: InputDecoration(labelText: l10n.amount, prefixText: '$currency '),
            ),
            const SizedBox(height: Spacing.l),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              validator: Validators.required(l10n),
              decoration: InputDecoration(labelText: l10n.description, prefixIcon: const Icon(Icons.short_text)),
            ),
            const SizedBox(height: Spacing.l),
            DropdownMenu<TransactionCategory>(
              key: ValueKey(_category.type),
              initialSelection: _category,
              expandedInsets: EdgeInsets.zero,
              label: Text(l10n.category),
              leadingIcon: Icon(_category.icon),
              onSelected: (c) => setState(() => _category = c ?? _category),
              dropdownMenuEntries: [
                for (final c in TransactionCategory.of(_category.type))
                  DropdownMenuEntry(value: c, label: c.label(l10n), leadingIcon: Icon(c.icon)),
              ],
            ),
            const SizedBox(height: Spacing.l),
            TextFormField(
              key: ValueKey(_date),
              readOnly: true,
              initialValue: MaterialLocalizations.of(context).formatFullDate(_date),
              onTap: _pickDate,
              decoration: InputDecoration(labelText: l10n.date, prefixIcon: const Icon(Icons.event_outlined)),
            ),
            const SizedBox(height: Spacing.l),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.noteOptional, alignLabelWithHint: true),
            ),
            if (_isEdit) ...[
              const SizedBox(height: Spacing.xxl),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: context.colors.error),
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteTransaction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

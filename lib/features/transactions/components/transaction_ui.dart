import 'package:emiliano_cesare_flutter_template/core/utils/money.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/l10n/gen/app_localizations.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:flutter/material.dart';

/// Presentation of the domain enums (kept out of the model).
extension TransactionCategoryUi on TransactionCategory {
  IconData get icon => switch (this) {
    TransactionCategory.salary => Icons.work_outline,
    TransactionCategory.freelance => Icons.laptop_mac,
    TransactionCategory.gift => Icons.card_giftcard,
    TransactionCategory.otherIncome => Icons.savings_outlined,
    TransactionCategory.groceries => Icons.shopping_cart_outlined,
    TransactionCategory.restaurants => Icons.restaurant,
    TransactionCategory.transport => Icons.directions_bus_outlined,
    TransactionCategory.home => Icons.home_outlined,
    TransactionCategory.bills => Icons.receipt_long_outlined,
    TransactionCategory.health => Icons.favorite_outline,
    TransactionCategory.entertainment => Icons.movie_outlined,
    TransactionCategory.shopping => Icons.shopping_bag_outlined,
    TransactionCategory.travel => Icons.flight_outlined,
    TransactionCategory.otherExpense => Icons.more_horiz,
  };

  String label(AppLocalizations l10n) => switch (this) {
    TransactionCategory.salary => l10n.categorySalary,
    TransactionCategory.freelance => l10n.categoryFreelance,
    TransactionCategory.gift => l10n.categoryGift,
    TransactionCategory.otherIncome => l10n.categoryOtherIncome,
    TransactionCategory.groceries => l10n.categoryGroceries,
    TransactionCategory.restaurants => l10n.categoryRestaurants,
    TransactionCategory.transport => l10n.categoryTransport,
    TransactionCategory.home => l10n.categoryHome,
    TransactionCategory.bills => l10n.categoryBills,
    TransactionCategory.health => l10n.categoryHealth,
    TransactionCategory.entertainment => l10n.categoryEntertainment,
    TransactionCategory.shopping => l10n.categoryShopping,
    TransactionCategory.travel => l10n.categoryTravel,
    TransactionCategory.otherExpense => l10n.categoryOther,
  };
}

extension TransactionTypeUi on TransactionType {
  String label(AppLocalizations l10n) => switch (this) {
    TransactionType.income => l10n.typeIncome,
    TransactionType.expense => l10n.typeExpense,
  };
}

/// Category icon in a tonal circle (M3 list leading element).
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.category, {super.key});

  final TransactionCategory category;

  @override
  Widget build(BuildContext context) {
    final income = category.type == TransactionType.income;
    return CircleAvatar(
      backgroundColor: income ? context.appColors.successContainer : context.colors.secondaryContainer,
      foregroundColor: income ? context.appColors.onSuccessContainer : context.colors.onSecondaryContainer,
      child: Icon(category.icon),
    );
  }
}

/// Signed amount: income in the success color, expenses in the default text color.
class AmountText extends StatelessWidget {
  const AmountText(this.cents, {this.style, super.key});

  /// Positive for income, negative for expenses.
  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.textTheme.titleMedium;
    return Text(
      Money.format(cents, signed: true),
      style: base?.copyWith(color: cents > 0 ? context.appColors.success : null),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, this.showDate = false, super.key});

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = transaction.category.label(l10n);
    return ListTile(
      leading: CategoryAvatar(transaction.category),
      title: Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        showDate ? '$category · ${MaterialLocalizations.of(context).formatShortMonthDay(transaction.date)}' : category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AmountText(transaction.signedAmount, style: context.textTheme.labelLarge),
      onTap: onTap,
    );
  }
}

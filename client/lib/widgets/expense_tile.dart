import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/finance_account.dart';
import '../models/category.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../widgets/user_avatar.dart';
import 'package:keda/l10n/app_localizations.dart';

class ExpenseTile extends ConsumerWidget {
  final Expense expense;
  final List<FinanceAccount> accounts;
  final List<Category> categories;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.accounts,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    
    final account = accounts.firstWhere((a) => a.id == expense.accountId, orElse: () => accounts.first);
    final category = categories.firstWhere((c) => c.id == expense.categoryId, orElse: () => categories.first);
    final timeStr = DateFormat.Hm(locale).format(expense.date.toLocal());

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        // Swipe Right -> Delete
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteExpense),
            content: Text(l10n.deleteExpenseConfirm),
            actions: [
              TextButton(onPressed: () => ctx.pop(false), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () => ctx.pop(true),
                child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(expensesProvider.notifier).deleteExpense(expense.id);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: expense.user == null
          ? const CircleAvatar(
              child: Icon(Icons.receipt_long),
            )
          : UserAvatar(
              pictureUrl: expense.user!.pictureUrl,
              name: expense.user!.name,
              color: expense.user!.color,
            ),
        title: Text(expense.note ?? l10n.noNote),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$timeStr • ${category.name} • ${account.getLocalizedDisplayName(l10n)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (expense.user != null)
              Text(
                l10n.createdBy(expense.user!.name),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Formatters.formatMoney(expense.amount, locale),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (MediaQuery.of(context).size.width < 600) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ] else ...[
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                onPressed: () => context.push('/edit-expense/${expense.id}'),
                tooltip: l10n.editExpense,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.deleteExpense),
                      content: Text(l10n.deleteExpenseConfirm),
                      actions: [
                        TextButton(onPressed: () => ctx.pop(false), child: Text(l10n.cancel)),
                        TextButton(
                          onPressed: () => ctx.pop(true),
                          child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                  }
                },
                tooltip: l10n.deleteExpense,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        onTap: () => context.push('/edit-expense/${expense.id}'),
      ),
    );
  }
}

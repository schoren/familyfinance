import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';
import '../widgets/user_avatar.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allExpenses),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          return accountsAsync.when(
            data: (accounts) {
              return categoriesAsync.when(
                data: (categories) {
                  // Filter for current month/year
                  final now = DateTime.now();
                  final currentMonthExpenses = expenses.where((e) {
                    final localDate = e.date.toLocal();
                    return localDate.month == now.month && 
                           localDate.year == now.year;
                  }).toList();

                  if (currentMonthExpenses.isEmpty) {
                    return Center(child: Text(l10n.noExpensesThisMonth));
                  }

                  // Group by day for visual separation
                  final groupedExpenses = <String, List<Expense>>{};
                  for (final expense in currentMonthExpenses) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(expense.date.toLocal());
                    groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
                  }

                  final dateKeys = groupedExpenses.keys.toList();

                  return ListView.builder(
                    itemCount: dateKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = dateKeys[index];
                      final dayExpenses = groupedExpenses[dateKey]!;
                      final displayDate = DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(dayExpenses.first.date.toLocal());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              displayDate,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                ),
                            ),
                          ),
                          ...dayExpenses.map((expense) {
                            final account = accounts.firstWhere((a) => a.id == expense.accountId, orElse: () => accounts.first);
                            final category = categories.firstWhere((c) => c.id == expense.categoryId, orElse: () => categories.first);
                            final timeStr = DateFormat.Hm(Localizations.localeOf(context).toString()).format(expense.date.toLocal());

                            return ListTile(
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
                                    '$timeStr • ${category.name} • ${account.name}',
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
                              trailing: Text(
                                Formatters.formatMoney(expense.amount, locale),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.errorLoadingCategories)),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.errorLoadingAccounts)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorLoadingExpenses)),
      ),
    );
  }
}

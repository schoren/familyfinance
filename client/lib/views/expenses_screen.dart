import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../widgets/premium_refresh_indicator.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';
import '../models/finance_account.dart';
import '../widgets/user_avatar.dart';
import '../widgets/month_navigation_selector.dart';
import '../widgets/expense_tile.dart';

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
                  final currentMonthExpenses = expenses;

                  if (currentMonthExpenses.isEmpty) {
                    return PremiumRefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          ref.refresh(expensesProvider.future),
                          ref.refresh(accountsProvider.future),
                          ref.refresh(categoriesProvider.future),
                        ]);
                      },
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: MonthNavigationSelector(),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(l10n.noExpensesThisMonth),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by day for visual separation
                  final groupedExpenses = <String, List<Expense>>{};
                  for (final expense in currentMonthExpenses) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(expense.date.toLocal());
                    groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
                  }

                  final dateKeys = groupedExpenses.keys.toList();

                  return PremiumRefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        ref.refresh(expensesProvider.future),
                        ref.refresh(accountsProvider.future),
                        ref.refresh(categoriesProvider.future),
                      ]);
                    },
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: MonthNavigationSelector(),
                        ),
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: dateKeys.length,
                            itemBuilder: (context, index) {
                              final dateKey = dateKeys[index];
                              final dayExpenses = groupedExpenses[dateKey]!;
                              final displayDate = DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(dayExpenses.first.date.toLocal());
                              
                              // Calculate daily total
                              final dailyTotal = dayExpenses.fold<double>(
                                0.0,
                                (sum, expense) => sum + expense.amount,
                              );
      
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
                                    return ExpenseTile(
                                      expense: expense,
                                      accounts: accounts,
                                      categories: categories,
                                    );
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    child: Column(
                                      children: [
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Daily Total: ',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              Formatters.formatMoney(dailyTotal, locale),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.errorLoadingCategories)),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.errorLoadingAccounts)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorLoadingExpenses)),
      ),
    );
  }
}

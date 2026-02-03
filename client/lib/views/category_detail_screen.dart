import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';
import '../widgets/month_navigation_selector.dart';
import '../widgets/expense_tile.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final remaining = ref.watch(categoryRemainingProvider(categoryId));

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => categories.first
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(category.name),
          ),
          body: expensesAsync.when(
             data: (expenses) {
               return accountsAsync.when(
                 data: (accounts) {
                   final currentMonthExpenses = expenses.where((e) => e.categoryId == categoryId).toList();
                   
                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: MonthNavigationSelector(),
                        ),
                        Card(
                          margin: const EdgeInsets.all(16),
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             children: [
                               Text(
                                 '${l10n.monthlyBudget}: ${Formatters.formatMoney(category.monthlyBudget, locale)}',
                                 style: Theme.of(context).textTheme.titleMedium,
                               ),
                               const SizedBox(height: 16),
                               Text(
                                 l10n.remainingLabel,
                                 style: Theme.of(context).textTheme.bodyMedium,
                               ),
                               Text(
                                 Formatters.formatMoney(remaining, locale),
                                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                   color: remaining < 0 ? Colors.red : Colors.green,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                               const SizedBox(height: 8),
                               LinearProgressIndicator(
                                 value: remaining > 0 ? (remaining / category.monthlyBudget) : 0,
                                 backgroundColor: Colors.grey[200],
                                 valueColor: AlwaysStoppedAnimation<Color>(
                                   remaining < 0 ? Colors.red : Colors.green,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                       
                       const Divider(),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         child: Align(
                           alignment: Alignment.centerLeft,
                           child: Text(
                             l10n.historyThisMonth,
                             style: Theme.of(context).textTheme.titleSmall,
                           ),
                         ),
                       ),
                       
                        Expanded(
                          child: currentMonthExpenses.isEmpty 
                            ? Center(child: Text(l10n.noExpensesThisMonth))
                            : (() {
                                final groupedExpenses = <String, List<Expense>>{};
                                for (final expense in currentMonthExpenses) {
                                  final dateKey = '${expense.date.toLocal().year}-${expense.date.toLocal().month}-${expense.date.toLocal().day}';
                                  groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
                                }

                                final dateKeys = groupedExpenses.keys.toList();

                                return ListView.builder(
                                  itemCount: dateKeys.length,
                                  itemBuilder: (context, index) {
                                    final dateKey = dateKeys[index];
                                    final dayExpenses = groupedExpenses[dateKey]!;
                                    // Custom date formatting to avoid intl date format issues without more research
                                    final firstDate = dayExpenses.first.date.toLocal();
                                    final displayDate = '${firstDate.day}/${firstDate.month}/${firstDate.year}';

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
                                );
                              })(),
                        ),
                     ],
                   );
                 },
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (_, _) => Center(child: Text(l10n.errorLoadingAccounts)),
               );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (_, _) => Center(child: Text(l10n.errorLoadingExpenses)),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/new-expense/$categoryId'),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text(l10n.errorWithDetails(err.toString())))),
    );
  }
}

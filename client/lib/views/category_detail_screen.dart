import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';

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
                   final now = DateTime.now();
                   final currentMonthExpenses = expenses.where((e) {
                     final localDate = e.date.toLocal();
                     return e.categoryId == categoryId && 
                            localDate.month == now.month && 
                            localDate.year == now.year;
                   }).toList();
                   
                   return Column(
                     children: [
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
                                          final accountList = accounts.where((a) => a.id == expense.accountId);
                                          final account = accountList.isNotEmpty ? accountList.first : null;
                                          final timeStr = '${expense.date.toLocal().hour}:${expense.date.toLocal().minute.toString().padLeft(2, '0')}';

                                          return ListTile(
                                            leading: const CircleAvatar(
                                              child: Icon(Icons.attach_money),
                                            ),
                                            title: Text(expense.note ?? l10n.noNote),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$timeStr • ${account?.displayName ?? l10n.unknownAccount}',
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
                                        }),
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
                 error: (_, __) => Center(child: Text(l10n.errorLoadingAccounts)),
               );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (_, __) => Center(child: Text(l10n.errorLoadingExpenses)),
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

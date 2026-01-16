import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/user.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final remaining = ref.watch(categoryRemainingProvider(categoryId));

    final locale = Localizations.localeOf(context).toString();

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => categories.first // Should probably handle better but safe fallback
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(category.name),
          ),
          body: expensesAsync.when(
             data: (expenses) {
               return accountsAsync.when(
                 data: (accounts) {
                   // Filter expenses for this category
                   // TODO: We might want to filter by month/year too, similar to "Remaining" logic. 
                   // For now, let's show all for simplicity or match the existing logic which seemed to imply current month context.
                   // The user didn't specify, but "Budget" usually implies current month.
                   // Let's filter by current month/year to match the budget view.
                   final now = DateTime.now();
                   final currentMonthExpenses = expenses.where((e) {
                     final localDate = e.date.toLocal();
                     return e.categoryId == categoryId && 
                            localDate.month == now.month && 
                            localDate.year == now.year;
                   }).toList();
                   
                   return Column(
                     children: [
                       // Summary Card
                       Card(
                         margin: const EdgeInsets.all(16),
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             children: [
                               Text(
                                 'Presupuesto Mensual: ${Formatters.formatMoney(category.monthlyBudget, locale)}',
                                 style: Theme.of(context).textTheme.titleMedium,
                               ),
                               const SizedBox(height: 16),
                               Text(
                                 'Restante',
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
                             'Historial (Este mes)',
                             style: Theme.of(context).textTheme.titleSmall,
                           ),
                         ),
                       ),
                       
                       // Expense List
                        Expanded(
                          child: currentMonthExpenses.isEmpty 
                            ? const Center(child: Text('No hay gastos este mes'))
                            : (() {
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
                                          final accountList = accounts.where((a) => a.id == expense.accountId);
                                          final account = accountList.isNotEmpty ? accountList.first : null;
                                          final timeStr = DateFormat.Hm(Localizations.localeOf(context).toString()).format(expense.date.toLocal());

                                          return ListTile(
                                            leading: const CircleAvatar(
                                              child: Icon(Icons.attach_money),
                                            ),
                                            title: Text(expense.note ?? 'Sin nota'),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$timeStr • ${account?.name ?? "Cuenta desconocida"}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                                if (expense.user != null)
                                                  Text(
                                                    'Creado por: ${expense.user!.name}',
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
                              })(),
                        ),
                     ],
                   );
                 },
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (_, __) => const Center(child: Text('Error cargando cuentas')),
               );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (_, __) => const Center(child: Text('Error cargando gastos')),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/new-expense/$categoryId'),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

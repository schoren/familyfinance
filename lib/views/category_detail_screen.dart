import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final remaining = ref.watch(categoryRemainingProvider(categoryId));

    final currencyFormat = NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '\$');

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
                   final currentMonthExpenses = expenses.where((e) => 
                     e.categoryId == categoryId && 
                     e.date.month == now.month && 
                     e.date.year == now.year
                   ).toList();
                   
                   // Sort by date descending
                   currentMonthExpenses.sort((a, b) => b.date.compareTo(a.date));

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
                                 'Presupuesto Mensual: ${currencyFormat.format(category.monthlyBudget)}',
                                 style: Theme.of(context).textTheme.titleMedium,
                               ),
                               const SizedBox(height: 16),
                               Text(
                                 'Restante',
                                 style: Theme.of(context).textTheme.bodyMedium,
                               ),
                               Text(
                                 currencyFormat.format(remaining),
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
                           : ListView.builder(
                               itemCount: currentMonthExpenses.length,
                               itemBuilder: (context, index) {
                                 final expense = currentMonthExpenses[index];
                                 final accountList = accounts.where((a) => a.id == expense.accountId);
                                 final account = accountList.isNotEmpty ? accountList.first : null; 
                                 // Actually accounts should exist if expenses exist with that ID ideally.

                                 return ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.attach_money),
                                    ),
                                    title: Text(expense.note ?? 'Sin nota'),
                                    subtitle: Text(
                                      '${DateFormat('dd/MM/yyyy').format(expense.date)} • ${account?.name ?? "Cuenta desconocida"}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    trailing: Text(
                                      currencyFormat.format(expense.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                 );
                               },
                             ),
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

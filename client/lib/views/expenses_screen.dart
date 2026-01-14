import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final currencyFormat = NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Gastos'),
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
                    return const Center(child: Text('No hay gastos este mes'));
                  }

                  return ListView.builder(
                    itemCount: currentMonthExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = currentMonthExpenses[index];
                      final account = accounts.firstWhere((a) => a.id == expense.accountId, orElse: () => accounts.first);
                      final category = categories.firstWhere((c) => c.id == expense.categoryId, orElse: () => categories.first);

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(expense.note ?? 'Sin nota'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(expense.date.toLocal())} • ${category.name} • ${account.name}',
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
                          currencyFormat.format(expense.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error cargando categorías')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error cargando cuentas')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error cargando gastos')),
      ),
    );
  }
}

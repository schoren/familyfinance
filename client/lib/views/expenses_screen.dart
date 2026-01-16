import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/user.dart';
import '../widgets/user_avatar.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final locale = Localizations.localeOf(context).toString();

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
                              title: Text(expense.note ?? 'Sin nota'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$timeStr • ${category.name} • ${account.name}',
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

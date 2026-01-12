import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_providers.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import 'widgets/month_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final (totalBudget, totalSpent) = ref.watch(monthlyTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          ref.watch(expensesProvider).when(
            data: (expenses) => Center(child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Gastos: ${expenses.length}', style: const TextStyle(fontSize: 12)),
            )),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: MonthSummaryCard(
              totalBudget: totalBudget,
              totalSpent: totalSpent,
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 600) {
                    crossAxisCount = 3;
                  }
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 6;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final remaining = ref.watch(categoryRemainingProvider(category.id));
                      final progress = remaining > 0 ? (remaining / category.monthlyBudget) : 0.0;
                      final currencyFormat = NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '\$');
                      
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () => context.push('/new-expense/${category.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 24.0), // Space for the menu icon
                                      child: Text(
                                        category.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      currencyFormat.format(remaining),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: remaining < 0 ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.red,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'details') {
                                    context.push('/category/${category.id}');
                                  } else if (value == 'edit') {
                                    context.push('/manage-category?id=${category.id}');
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Eliminar Categoría'),
                                        content: Text('¿Estás seguro de que deseas eliminar "${category.name}"?'),
                                        actions: [
                                          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancelar')),
                                          TextButton(
                                            onPressed: () async {
                                              ctx.pop();
                                              await ref.read(repositoryProvider).deleteCategory(category.id);
                                              ref.invalidate(categoriesProvider);
                                            },
                                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    height: 32,
                                    child: Text('Ver Detalle', style: TextStyle(fontSize: 14)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    height: 32,
                                    child: Text('Editar', style: TextStyle(fontSize: 14)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    height: 32,
                                    child: Text('Eliminar', style: TextStyle(fontSize: 14, color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/manage-category');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

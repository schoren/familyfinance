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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Center(
                child: Text(
                  'Family Finance',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Presupuestos'),
              onTap: () {
                context.pop();
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Cuentas'),
              onTap: () {
                context.pop();
                context.push('/manage-accounts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Invitar Miembro'),
              onTap: () {
                context.pop();
                _showInviteDialog(context, ref);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
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
                                    context.push('/manage-category/edit/${category.id}');
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
                                              await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
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
          context.push('/manage-category/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();

    void submit() async {
      final email = emailController.text.trim();
      if (email.isEmpty) return;

      try {
        // Show loading indicator or disable button could be nice, but simple for now
        Navigator.pop(context); // Close dialog first or show loading? 
        // User asked to submit on enter.
        // Let's close dialog on success, or keep open on error?
        // The original logic closed it inside the try block after success.
        // But popping first is risky if it fails.
        // Let's stick to original logic: keep dialog open while sending?
        // The original code popped AFTER `createInvitation` success.
        // BUT `showDialog` returns a Future that completes when popped.
        // If we want to show a snackbar on the underlying screen, we need context.
        
        // Let's recreate the logic but reusable.
        // NOTE: We can't pop `context` if we are not in the dialog context anymore if we pop too early.
        // Actually, let's keep it simple: call createInvitation, then pop.
        
        await ref.read(apiClientProvider).createInvitation(email);
        
        if (context.mounted) {
           // We might need to check if dialog is still open? 
           // If onSubmitted calls this, the dialog is open.
           // If button calls this, the dialog is open.
           // However, we popped in the original code. 
           // Wait, the original code had `Navigator.pop(context)` INSIDE the `if (context.mounted)`.
           // But `showDialog` creates a new route. We need to pop THAT route.
           // Just calling `Navigator.pop(context)` works for the dialog.
           
           // Issue: If we use `onSubmitted`, we are in the TextField.
           Navigator.of(context).pop(); // Close the dialog
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Invitación enviada con éxito')),
           );
        }
      } catch (e) {
        if (context.mounted) {
          // If we failed, maybe we DON'T want to close the dialog?
          // The previous logic didn't close it on error (it was in catch block printing to snackbar).
          // But to show snackbar we probably want to be on the screen below?
          // Or we can show snackbar above dialog.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar invitación: $e')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog( // Use ctx to avoid confusion, though implies same variable shadowing
        title: const Text('Invitar Miembro'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'ejemplo@gmail.com',
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => submit(),
          autofocus: true, // Nice to have
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: submit,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

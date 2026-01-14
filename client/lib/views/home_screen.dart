import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      'Keda',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
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
              leading: const Icon(Icons.people),
              title: const Text('Miembros'),
              onTap: () {
                context.pop();
                context.push('/members');
              },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Versión Cliente: ${String.fromEnvironment('APP_VERSION', defaultValue: 'dev')}',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  ref.watch(serverVersionProvider).when(
                    data: (version) => Text(
                      'Versión Servidor: $version',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    loading: () => const Text(
                      'Versión Servidor: cargando...',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    error: (_, __) => const Text(
                      'Versión Servidor: error',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
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
                  if (constraints.maxWidth > 800) {
                    crossAxisCount = 4;
                  }
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 6;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final remaining = ref.watch(categoryRemainingProvider(category.id));
                      final progress = remaining > 0 ? (remaining / category.monthlyBudget) : 0.0;
                      final currencyFormat = NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '\$');
                      
                      Color progressColor;
                      if (progress > 0.5) {
                        progressColor = const Color(0xFF22C55E); // Green
                      } else if (progress > 0.2) {
                        progressColor = const Color(0xFFFACC15); // Amber
                      } else {
                        progressColor = const Color(0xFFEF4444); // Red
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () => context.push('/new-expense/${category.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 24.0),
                                        child: Text(
                                          category.name.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    FittedBox(
                                      child: Text(
                                        currencyFormat.format(remaining),
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 24,
                                          color: remaining < 0 ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    color: progressColor,
                                  ),
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
}

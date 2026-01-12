import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_providers.dart';
import '../models/expense.dart';
import 'package:uuid/uuid.dart';

class NewExpenseScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const NewExpenseScreen({super.key, required this.categoryId});

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto válido')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta')),
      );
      return;
    }

    final newExpense = Expense(
      id: const Uuid().v4(),
      date: DateTime.now(),
      categoryId: widget.categoryId,
      accountId: _selectedAccountId!,
      amount: amount,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    await ref.read(expensesProvider.notifier).addExpense(newExpense);
    
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final accounts = ref.watch(accountsProvider).value ?? [];
    
    final category = categories.firstWhere(
      (c) => c.id == widget.categoryId, 
      orElse: () => categories.first, // Fallback safety
    );

    // Initialize selected account if needed and accounts are available
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gasto en ${category.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            if (accounts.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Cuenta',
                  border: OutlineInputBorder(),
                ),
                items: accounts.map((account) {
                  return DropdownMenuItem(
                    value: account.id,
                    child: Text(account.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                  });
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    const Text('No tienes cuentas creadas.'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/manage-accounts'),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear mi primera cuenta'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: accounts.isEmpty ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('GUARDAR', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

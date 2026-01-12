import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/finance_account.dart';
import '../models/account_type.dart';
import '../providers/data_providers.dart';

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Cuentas'),
      ),
      body: accountsAsync.when(
        data: (accounts) => ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return ListTile(
              leading: Icon(
                account.type == AccountType.card ? Icons.credit_card : (account.type == AccountType.bank ? Icons.account_balance : Icons.money),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(account.displayName),
              subtitle: Text(
                account.type == AccountType.card 
                  ? "Tarjeta" 
                  : (account.type == AccountType.bank ? "Cuenta Bancaria" : "Efectivo"),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAccountDialog(context, ref, account: account),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, ref, account),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAccountDialog(BuildContext context, WidgetRef ref, {FinanceAccount? account}) {
    final isEditing = account != null;
    final nameController = TextEditingController(text: account?.name);
    final brandController = TextEditingController(text: account?.brand);
    final bankController = TextEditingController(text: account?.bank);
    AccountType selectedType = account?.type ?? AccountType.cash;
    String? selectedBrand = account?.brand;

    final cardBrands = ['Visa', 'Mastercard', 'AMEX', 'Maestro', 'Cabal'];
    if (selectedBrand != null && !cardBrands.contains(selectedBrand)) {
      // If the existing brand is not in our list (legacy or custom), we might want to handle it.
      // For now, let's just make sure it's valid for the dropdown if we want to show it.
      // Otherwise, we can add it to the list temporarily.
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<AccountType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: AccountType.cash, child: Text('Efectivo')),
                    DropdownMenuItem(value: AccountType.card, child: Text('Tarjeta')),
                    DropdownMenuItem(value: AccountType.bank, child: Text('Cuenta Bancaria')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedType = value);
                  },
                ),
                if (selectedType == AccountType.card) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBrand,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    items: cardBrands.map((brand) {
                      return DropdownMenuItem(value: brand, child: Text(brand));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedBrand = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bankController,
                    decoration: const InputDecoration(labelText: 'Banco'),
                  ),
                ] else if (selectedType == AccountType.bank) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre de la cuenta'),
                  ),
                ],
                // For cash, no extra fields.
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final newAccount = FinanceAccount(
                  id: account?.id ?? const Uuid().v4(),
                  name: selectedType == AccountType.bank ? nameController.text : (selectedType == AccountType.cash ? "Efectivo" : nameController.text),
                  type: selectedType,
                  brand: selectedType == AccountType.card ? selectedBrand : null,
                  bank: selectedType == AccountType.card ? bankController.text : null,
                  displayName: '', // Computed by backend
                );

                if (isEditing) {
                  await ref.read(accountsProvider.notifier).updateAccount(newAccount);
                } else {
                  await ref.read(accountsProvider.notifier).createAccount(newAccount);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, FinanceAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text('¿Deseas eliminar la cuenta "${account.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(accountsProvider.notifier).deleteAccount(account.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

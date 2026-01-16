import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../models/account_type.dart';
import '../providers/data_providers.dart';
import '../models/finance_account.dart';

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageAccounts),
      ),
      body: accountsAsync.when(
        data: (accounts) => ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            String subtitle;
            if (account.type == AccountType.card) {
              subtitle = l10n.card;
            } else if (account.type == AccountType.bank) {
              subtitle = l10n.bankAccount;
            } else {
              subtitle = l10n.cash;
            }

            return ListTile(
              leading: Icon(
                account.type == AccountType.card ? Icons.credit_card : (account.type == AccountType.bank ? Icons.account_balance : Icons.money),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(account.displayName),
              subtitle: Text(subtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: account.type == AccountType.cash ? Colors.grey : Colors.blue),
                    onPressed: account.type == AccountType.cash 
                      ? null 
                      : () => context.push('/manage-accounts/edit/${account.id}'),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: account.type == AccountType.cash ? Colors.grey : Colors.red),
                    onPressed: account.type == AccountType.cash 
                      ? null 
                      : () => _showDeleteConfirmation(context, ref, account),
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
        onPressed: () => context.push('/manage-accounts/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, FinanceAccount account) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm(account.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              await ref.read(accountsProvider.notifier).deleteAccount(account.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

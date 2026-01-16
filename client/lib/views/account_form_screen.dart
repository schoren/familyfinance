import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../models/finance_account.dart';
import '../models/account_type.dart';
import '../providers/data_providers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const AccountFormScreen({super.key, this.accountId});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankController = TextEditingController();
  
  AccountType _selectedType = AccountType.card; // Default to card instead of cash
  String? _selectedBrand;
  bool _isLoading = false;
  bool _isInitialized = false;

  final cardBrands = ['Visa', 'Mastercard', 'AMEX', 'Maestro', 'Cabal'];

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _initializeFromAccount(FinanceAccount account) {
    if (_isInitialized) return;
    _selectedType = account.type;
    _selectedBrand = account.brand;
    _nameController.text = account.name;
    _bankController.text = account.bank ?? '';
    _isInitialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newAccount = FinanceAccount(
        id: widget.accountId ?? const Uuid().v4(),
        name: _selectedType == AccountType.bank ? _nameController.text : (_selectedType == AccountType.cash ? AppLocalizations.of(context)!.cash : _nameController.text),
        type: _selectedType,
        brand: _selectedType == AccountType.card ? _selectedBrand : null,
        bank: _selectedType == AccountType.card ? _bankController.text : null,
        displayName: '', // Computed by backend
      );

      String resultId = newAccount.id;
      if (widget.accountId != null) {
        await ref.read(accountsProvider.notifier).updateAccount(newAccount);
      } else {
        final created = await ref.read(accountsProvider.notifier).createAccount(newAccount);
        resultId = created.id;
      }

      if (mounted) {
        context.pop(resultId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.accountId != null;
    final accountsAsync = ref.watch(accountsProvider);

    if (isEditing) {
      return accountsAsync.when(
        data: (accounts) {
          final account = accounts.firstWhere(
            (a) => a.id == widget.accountId,
            orElse: () => FinanceAccount(id: '', type: AccountType.cash, name: '', displayName: ''),
          );
          if (account.id.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(AppLocalizations.of(context)!.error)),
              body: Center(child: Text(AppLocalizations.of(context)!.accountNotFound)),
            );
          }
          _initializeFromAccount(account);
          return _buildForm(context, isEditing, accountsAsync);
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      );
    }

    return _buildForm(context, isEditing, accountsAsync);
  }

  Widget _buildForm(BuildContext context, bool isEditing, AsyncValue<List<FinanceAccount>> accountsAsync) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editAccount : AppLocalizations.of(context)!.newAccount),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.type,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  if (!isEditing && accountsAsync.maybeWhen(data: (accounts) => !accounts.any((a) => a.type == AccountType.cash), orElse: () => true))
                    DropdownMenuItem(value: AccountType.cash, child: Text(AppLocalizations.of(context)!.cash)),
                  DropdownMenuItem(value: AccountType.card, child: Text(AppLocalizations.of(context)!.card)),
                  DropdownMenuItem(value: AccountType.bank, child: Text(AppLocalizations.of(context)!.bankAccount)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              if (_selectedType == AccountType.card) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.brand,
                    border: const OutlineInputBorder(),
                  ),
                  items: cardBrands.map((brand) {
                    return DropdownMenuItem(value: brand, child: Text(brand));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedBrand = value);
                  },
                  validator: (value) => value == null ? AppLocalizations.of(context)!.selectAnAccount : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankController,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.bank,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.enterBank : null,
                  onFieldSubmitted: (_) => _save(),
                ),
              ] else if (_selectedType == AccountType.bank) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.accountName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.enterName : null,
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.save, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

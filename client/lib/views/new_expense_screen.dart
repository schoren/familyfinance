import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/finance_account.dart';
import 'package:uuid/uuid.dart';

class NewExpenseScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const NewExpenseScreen({super.key, required this.categoryId});

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedAccountId;
  static const String _createNewAccountKey = 'CREATE_NEW_ACCOUNT';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == widget.categoryId,
          orElse: () => Category(id: '', name: 'Cargando...', monthlyBudget: 0),
        );
        
        if (category.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Categoría no encontrada')),
          );
        }

        return accountsAsync.when(
          data: (accounts) {
             // Initialize selected account if needed and accounts are available
            if (_selectedAccountId == null && accounts.isNotEmpty) {
              _selectedAccountId = accounts.first.id;
            }
            return _buildForm(context, category, accounts);
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildForm(BuildContext context, Category category, List<FinanceAccount> accounts) {
    final remaining = ref.watch(categoryRemainingProvider(category.id));
    final currencyFormat = NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '\$');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Impact Preview
                Center(
                  child: ListenableBuilder(
                    listenable: _amountController,
                    builder: (context, _) {
                      final inputAmount = double.tryParse(_amountController.text) ?? 0.0;
                      final result = remaining - inputAmount;
                      final isNegative = result < 0;
  
                      return Column(
                        children: [
                          Text(
                            currencyFormat.format(remaining),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(remaining),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 18,
                              color: const Color(0xFF64748B),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(result),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isNegative ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                            ),
                          ),
                          Text(
                            'RESTANTE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _amountController,
                  focusNode: _focusNode,
                  autofocus: false,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.jetBrainsMono(fontSize: 32, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'MONTO',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa un monto';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'CUENTA',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: [
                    ...accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.displayName),
                      );
                    }),
                    const DropdownMenuItem(
                      value: _createNewAccountKey,
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 20, color: Color(0xFF22C55E)),
                          SizedBox(width: 8),
                          Text('Añadir nueva cuenta...', 
                            style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == _createNewAccountKey) {
                      final newAccountId = await context.push<String>('/manage-accounts/new');
                      if (newAccountId != null) {
                        setState(() {
                          _selectedAccountId = newAccountId;
                        });
                      }
                    } else {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    }
                  },
                  validator: (value) => (value == null || value == _createNewAccountKey) ? 'Selecciona una cuenta' : null,
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('No tienes cuentas creadas.'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newAccountId = await context.push<String>('/manage-accounts/new');
                          if (newAccountId != null) {
                            setState(() {
                              _selectedAccountId = newAccountId;
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear mi primera cuenta'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final suggestions = ref.read(suggestedNotesProvider(widget.categoryId)).value ?? [];
                  if (textEditingValue.text.isEmpty) {
                    return suggestions;
                  }
                  return suggestions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _noteController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'NOTA (OPCIONAL)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    onChanged: (value) {
                      _noteController.text = value;
                    },
                    onFieldSubmitted: (_) => _save(),
                  );
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: accounts.isEmpty ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'GUARDAR GASTO', 
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

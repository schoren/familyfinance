import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../utils/ios_keyboard_fix.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/finance_account.dart';
import 'package:uuid/uuid.dart';

class NewExpenseScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? expenseId;
  const NewExpenseScreen({super.key, this.categoryId, this.expenseId});

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  static const String _createNewAccountKey = 'CREATE_NEW_ACCOUNT';
  late DateTime _selectedDate;
  bool _isEditing = false;
  Expense? _originalExpense;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _selectedDate = DateTime.now();

    if (widget.expenseId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExpense();
      });
    } else {
      final selectedMonth = ref.read(selectedMonthProvider);
      final now = DateTime.now();
      if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
        _selectedDate = now;
      } else {
        _selectedDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      }
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        IOSKeyboardFix.stop();
        _focusNode.requestFocus();
      }
    });
  }

  void _loadExpense() {
    final expenses = ref.read(expensesProvider).value ?? [];
    final expense = expenses.firstWhere((e) => e.id == widget.expenseId, orElse: () => throw Exception('Expense not found'));
    _originalExpense = expense;
    _amountController.text = expense.amount.toString();
    _noteController.text = expense.note ?? '';
    _selectedAccountId = expense.accountId;
    _selectedCategoryId = expense.categoryId;
    _selectedDate = expense.date.toLocal();
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExpense),
        content: Text(l10n.deleteExpenseConfirm),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(expensesProvider.notifier).deleteExpense(widget.expenseId!);
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectAccount)),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    
    if (_isEditing && _originalExpense != null) {
      final updatedExpense = _originalExpense!.copyWith(
        date: _selectedDate,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        amount: amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      await ref.read(expensesProvider.notifier).updateExpense(updatedExpense);
    } else {
      final newExpense = Expense(
        id: const Uuid().v4(),
        date: _selectedDate,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        amount: amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      await ref.read(expensesProvider.notifier).addExpense(newExpense);
    }
    
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
        final l10n = AppLocalizations.of(context)!;
        final category = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => Category(id: '', name: l10n.loading, monthlyBudget: 0),
        );
        
        if (category.id.isEmpty && !_isEditing) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.error)),
            body: Center(child: Text(l10n.categoryNotFound)),
          );
        }

        return accountsAsync.when(
          data: (accounts) {
             // Initialize selected account if needed and accounts are available
            if (_selectedAccountId == null && accounts.isNotEmpty) {
              _selectedAccountId = accounts.first.id;
            }
            return _buildForm(context, category, accounts, categoriesAsync);
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildForm(BuildContext context, Category category, List<FinanceAccount> accounts, AsyncValue<List<Category>> categoriesAsync) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = ref.watch(categoryRemainingProvider(category.id));
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editExpense : l10n.newExpense),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
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
                            Formatters.formatMoney(remaining, locale),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatMoney(remaining, locale),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 18,
                              color: const Color(0xFF64748B),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatMoney(result, locale),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isNegative ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                            ),
                          ),
                          Text(
                            l10n.remainingLabel,
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
                    labelText: l10n.amount,
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
                    if (value == null || value.isEmpty) return l10n.enterAmount;
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return l10n.invalidAmount;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Category Selector (only if editing or if we want flexibility)
                if (_isEditing)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: l10n.categories,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    items: categoriesAsync.value?.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                if (_isEditing) const SizedBox(height: 24),
              const SizedBox(height: 24),
              if (accounts.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 16),
                  decoration: InputDecoration(
                    labelText: l10n.account,
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
                        child: Text(account.getLocalizedDisplayName(l10n)),
                      );
                    }),
                    DropdownMenuItem(
                      value: _createNewAccountKey,
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 20, color: Color(0xFF22C55E)),
                          const SizedBox(width: 8),
                          Text(l10n.addNewAccount, 
                            style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
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
                  validator: (value) => (value == null || value == _createNewAccountKey) ? l10n.selectAnAccount : null,
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
                      Text(l10n.noAccountsCreated),
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
                        label: Text(l10n.createFirstAccount),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Date Picker
              InkWell(
                onTap: () async {
                  final selectedMonth = ref.read(selectedMonthProvider);
                  final now = DateTime.now();
                  final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
                  
                  final firstDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
                  final lastDate = isCurrentMonth 
                    ? now 
                    : DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate.isAfter(lastDate) ? lastDate : (_selectedDate.isBefore(firstDate) ? firstDate : _selectedDate),
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        _selectedDate.hour,
                        _selectedDate.minute,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.date,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            DateFormat.yMMMMd(locale).format(_selectedDate),
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final suggestions = ref.read(suggestedNotesProvider(_selectedCategoryId ?? '')).value ?? [];
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
                      labelText: l10n.noteOptional,
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
                    onEditingComplete: () {
                      _noteController.text = controller.text;
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
                    _isEditing ? l10n.updateExpense : l10n.saveExpense, 
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _showDeleteConfirmation,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      l10n.deleteExpense,
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

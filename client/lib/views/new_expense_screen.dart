import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../utils/formatters.dart';
import '../utils/web_utils.dart'; // Import for forceNumericInput
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
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  bool _isEditing = false;
  Expense? _originalExpense;

  int _currentStep = 1;

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

    // Auto-focus logic with JS fix
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        forceNumericInput();
      }
    });

    // Request focus on amount field initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentStep == 1) {
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

  Future<void> _save(List<FinanceAccount> accounts) async {
    final l10n = AppLocalizations.of(context)!;
    if (_amountController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterAmount)),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectCategory)),
      );
      return;
    }

    // Use first available account if none selected (Step 1 save)
    final accountId = _selectedAccountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
    
    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectAccount)),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidAmount)),
      );
      return;
    }
    
    if (_isEditing && _originalExpense != null) {
      final updatedExpense = _originalExpense!.copyWith(
        date: _selectedDate,
        categoryId: _selectedCategoryId!,
        accountId: accountId,
        amount: amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      await ref.read(expensesProvider.notifier).updateExpense(updatedExpense);
    } else {
      final newExpense = Expense(
        id: const Uuid().v4(),
        date: _selectedDate,
        categoryId: _selectedCategoryId!,
        accountId: accountId,
        amount: amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      await ref.read(expensesProvider.notifier).addExpense(newExpense);
    }
    
    if (mounted) {
      context.pop();
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_amountController.text.isEmpty || (double.tryParse(_amountController.text) ?? 0) <= 0) {
        return;
      }
    }
    setState(() {
      _currentStep++;
    });
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
            return _buildWizard(context, category, accounts, categoriesAsync);
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildWizard(BuildContext context, Category category, List<FinanceAccount> accounts, AsyncValue<List<Category>> categoriesAsync) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = ref.watch(categoryRemainingProvider(category.id));
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editExpense : l10n.newExpense),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: _currentStep > 1 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentStep--),
            )
          : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: List.generate(3, (index) {
                  final stepNum = index + 1;
                  final isActive = stepNum <= _currentStep;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (stepNum == _currentStep)
                          Text(
                            l10n.stepXofY(stepNum.toString(), '3'),
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF22C55E)),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStepContent(context, category, accounts, categoriesAsync, remaining, locale),
                ),
              ),
            ),
            _buildBottomButtons(accounts),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, Category category, List<FinanceAccount> accounts, AsyncValue<List<Category>> categoriesAsync, double remaining, String locale) {
    final l10n = AppLocalizations.of(context)!;

    switch (_currentStep) {
      case 1:
        return _buildStep1(context, remaining, locale, l10n);
      case 2:
        return _buildStep2(context, locale, l10n);
      case 3:
        return _buildStep3(context, accounts, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(BuildContext context, double remaining, String locale, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Impact Preview
          ListenableBuilder(
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
          const SizedBox(height: 60),
          Semantics(
            label: l10n.amount,
            child: TextFormField(
              controller: _amountController,
              focusNode: _focusNode,
              onTap: () => forceNumericInput(),
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
              style: GoogleFonts.jetBrainsMono(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, String locale, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.date,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final selectedMonth = ref.read(selectedMonthProvider);
              final now = DateTime.now();
              final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
              final firstDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
              final lastDate = isCurrentMonth ? now : DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate.isAfter(lastDate) ? lastDate : (_selectedDate.isBefore(firstDate) ? firstDate : _selectedDate),
                firstDate: firstDate,
                lastDate: lastDate,
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF22C55E)),
                  const SizedBox(width: 12),
                  Text(DateFormat.yMMMMd(locale).format(_selectedDate), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.noteOptional,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final suggestions = ref.read(suggestedNotesProvider(_selectedCategoryId ?? '')).value ?? [];
              if (textEditingValue.text.isEmpty) return suggestions;
              return suggestions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) => _noteController.text = selection,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text.isEmpty && _noteController.text.isNotEmpty) {
                 controller.text = _noteController.text;
              }
              return Semantics(
                label: l10n.noteOptional,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.inter(fontSize: 16),
                  scrollPadding: const EdgeInsets.only(bottom: 200), // Safari fix
                  decoration: InputDecoration(
                    hintText: l10n.addNote,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onChanged: (value) => _noteController.text = value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(BuildContext context, List<FinanceAccount> accounts, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: accounts.length + 1,
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final newId = await context.push<String>('/manage-accounts/new');
                if (newId != null) setState(() => _selectedAccountId = newId);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addNewAccount),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: Color(0xFF22C55E)),
                foregroundColor: const Color(0xFF22C55E),
              ),
            ),
          );
        }

        final account = accounts[index];
        final isSelected = account.id == _selectedAccountId || (_selectedAccountId == null && index == 0);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () => setState(() => _selectedAccountId = account.id),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_balance_wallet, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(account.getLocalizedDisplayName(l10n), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold))),
                  if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(List<FinanceAccount> accounts) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _save(accounts),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: Text(
                _isEditing ? l10n.updateExpense : l10n.saveExpense, 
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ),
          if (_currentStep < 3) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _nextStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: Text(
                  _currentStep == 1 ? l10n.addDetails : l10n.chooseAccount,
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

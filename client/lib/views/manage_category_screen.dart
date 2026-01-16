import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../models/category.dart';

class ManageCategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const ManageCategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends ConsumerState<ManageCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _initializeFromCategory(Category category) {
    if (_isInitialized) return;
    _nameController.text = category.name;
    _budgetController.text = category.monthlyBudget.toStringAsFixed(0);
    _isInitialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final id = widget.categoryId ?? const Uuid().v4();
      final name = _nameController.text.trim();
      final budget = double.parse(_budgetController.text);

      final category = Category(
        id: id,
        name: name,
        monthlyBudget: budget,
        isActive: true,
      );

      if (widget.categoryId != null) {
        await ref.read(categoriesProvider.notifier).updateCategory(category);
      } else {
        await ref.read(categoriesProvider.notifier).createCategory(category);
      }
      
      // Refresh remaining provider if editing
      if (widget.categoryId != null) {
        ref.invalidate(categoryRemainingProvider(widget.categoryId!));
      }
      // Refresh summary as well
      ref.invalidate(currentMonthSummaryProvider);

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.categorySaved)),
          );
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
    final isEditing = widget.categoryId != null;
    final categoriesAsync = ref.watch(categoriesProvider);

    if (isEditing) {
      return categoriesAsync.when(
        data: (categories) {
          final category = categories.firstWhere(
            (c) => c.id == widget.categoryId,
            orElse: () => Category(id: '', name: '', monthlyBudget: 0),
          );
          if (category.id.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(AppLocalizations.of(context)!.error)),
              body: Center(child: Text(AppLocalizations.of(context)!.categoryNotFound)),
            );
          }
          _initializeFromCategory(category);
          return _buildForm(context, isEditing);
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.errorWithDetails(err.toString())))),
      );
    }

    return _buildForm(context, isEditing);
  }

  Widget _buildForm(BuildContext context, bool isEditing) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editCategory : AppLocalizations.of(context)!.newCategory),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.name,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.enterNamePlease;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.monthlyBudget,
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _save(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.enterBudgetPlease;
                  }
                  if (double.tryParse(value) == null) {
                    return AppLocalizations.of(context)!.invalidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
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

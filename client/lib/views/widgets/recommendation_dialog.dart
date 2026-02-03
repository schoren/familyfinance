import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/recommendation.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/formatters.dart';
import 'package:google_fonts/google_fonts.dart';

class RecommendationDialog extends ConsumerWidget {
  const RecommendationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return categoriesAsync.when(
      data: (categories) {
        double currentTotal = 0;
        double newTotal = 0;

        for (var cat in categories) {
          currentTotal += cat.monthlyBudget;
          
          final rec = state.recommendations.firstWhere(
            (r) => r.categoryId == cat.id,
            orElse: () => Recommendation(
              categoryId: '', 
              categoryName: '', 
              action: '', 
              amount: 0,
              isSelected: false,
            ),
          );

          if (rec.categoryId.isNotEmpty && rec.isSelected) {
            newTotal += rec.amount;
          } else {
            newTotal += cat.monthlyBudget;
          }
        }

        final delta = newTotal - currentTotal;

        return AlertDialog(
          title: Text(l10n.recommendationDialogTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = state.recommendations[index];
                      return CheckboxListTile(
                        title: Text(rec.categoryName),
                        subtitle: Text(
                          rec.action == 'increase' 
                            ? l10n.increaseTo(Formatters.formatMoney(rec.amount, locale))
                            : l10n.decreaseTo(Formatters.formatMoney(rec.amount, locale)),
                          style: TextStyle(
                            color: rec.action == 'increase' ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: rec.isSelected,
                        onChanged: (_) {
                          ref.read(recommendationProvider.notifier).toggleSelection(index);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      _buildSummaryRow(l10n.currentBudget, Formatters.formatMoney(currentTotal, locale)),
                      _buildSummaryRow(l10n.newBudget, Formatters.formatMoney(newTotal, locale), isBold: true),
                      _buildSummaryRow(
                        l10n.totalBudgetChange, 
                        '${delta >= 0 ? '+' : ''}${Formatters.formatMoney(delta, locale)}',
                        color: delta > 0 ? Colors.red : (delta < 0 ? Colors.green : null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(recommendationProvider.notifier).applyRecommendations();
                Navigator.of(context).pop();
              },
              child: Text(l10n.applySelected),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

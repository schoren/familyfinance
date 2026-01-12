import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;

  const MonthSummaryCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat('MMMM yyyy', locale).format(now);
    // Capitalize first letter
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final remaining = totalBudget - totalSpent;
    final isOverBudget = remaining < 0;
    
    final currencyFormat = NumberFormat.currency(locale: locale, symbol: '\$');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              formattedMonth,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  context,
                  'Presupuesto',
                  currencyFormat.format(totalBudget),
                  Colors.green,
                ),
                _buildInfoColumn(
                  context,
                  'Gastado',
                  currencyFormat.format(totalSpent),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (remaining / totalBudget).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.red,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                  ? 'Excedido por ${currencyFormat.format(-remaining)}'
                  : 'Quedan ${currencyFormat.format(remaining)}',
              style: TextStyle(
                color: isOverBudget ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoColumn(
    BuildContext context,
    String label,
    String amount,
    Color amountColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

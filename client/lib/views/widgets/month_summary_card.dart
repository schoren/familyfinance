import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../../utils/formatters.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat('MMMM yyyy', locale).format(now);
    // Capitalize first letter
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final remaining = totalBudget - totalSpent;
    final isOverBudget = remaining < 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/expenses'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              formattedMonth.toUpperCase(),
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  context,
                  l10n.budget,
                  Formatters.formatMoney(totalBudget, locale),
                  Colors.green,
                ),
                _buildInfoColumn(
                  context,
                  l10n.spent,
                  Formatters.formatMoney(totalSpent, locale),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (remaining / totalBudget).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining > 0.2 * totalBudget ? const Color(0xFF22C55E) : const Color(0xFFFACC15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isOverBudget
                  ? l10n.exceededBy(Formatters.formatMoney(-remaining, locale))
                  : l10n.remaining(Formatters.formatMoney(remaining, locale)),
              style: GoogleFonts.jetBrainsMono(
                color: isOverBudget ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
          style: GoogleFonts.jetBrainsMono(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

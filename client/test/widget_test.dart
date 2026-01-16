import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keda/views/widgets/month_summary_card.dart';
import 'utils/test_utils.dart';

void main() {
  testWidgets('MonthSummaryCard shows correct budget and spent values', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      createTestApp(
        home: const Scaffold(
          body: MonthSummaryCard(
            totalBudget: 1000.0,
            totalSpent: 400.0,
          ),
        ),
      ),
    );

    // Verify that our budget and spent text is present.
    expect(find.text('Presupuesto'), findsOneWidget);
    expect(find.text('Gastado'), findsOneWidget);
    
    // Note: Finding the exact formatted currency string might be tricky due to locale, 
    // but we can check if the numbers are there.
    expect(find.textContaining('1.000'), findsOneWidget);
    expect(find.textContaining('400'), findsOneWidget);
    
    // Check for remaining text
    expect(find.textContaining('QUEDAN'), findsOneWidget);
    expect(find.textContaining('600'), findsOneWidget);
  });

  testWidgets('MonthSummaryCard shows over budget message', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestApp(
        home: const Scaffold(
          body: MonthSummaryCard(
            totalBudget: 1000.0,
            totalSpent: 1200.0,
          ),
        ),
      ),
    );

    // Use find.text to match exactly or be more specific to avoid finding it in the amount text
    expect(find.textContaining('EXCEDIDO POR'), findsOneWidget);
    expect(find.textContaining('1.200'), findsOneWidget); // Total spent
    expect(find.textContaining('200'), findsAny); // Both in amount and in "Excedido por"
  });
}

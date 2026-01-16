import 'package:intl/intl.dart';

class Formatters {
  static String formatMoney(double amount, String locale) {
    final numberFormat = NumberFormat.decimalPattern(locale);
    // Ensure two decimal places for money
    numberFormat.minimumFractionDigits = 2;
    numberFormat.maximumFractionDigits = 2;
    return '\$${numberFormat.format(amount)}';
  }
}

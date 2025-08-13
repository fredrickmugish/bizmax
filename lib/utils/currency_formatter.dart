import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'sw_TZ',
    symbol: 'TSH ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,###').format(amount);
  }
}

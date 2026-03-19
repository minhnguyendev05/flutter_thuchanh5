import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String currency(double value) => _currency.format(value);
  static String date(DateTime date) => _dateFormat.format(date);
}

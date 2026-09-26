import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:intl/intl.dart';

/// Money as integer cents (never doubles): formatting in the app language
/// and currency (`CURRENCY` env key), parsing of user input.
abstract final class Money {
  static String format(int cents, {bool signed = false}) {
    final text = NumberFormat.simpleCurrency(name: AppConfig.currency).format(cents.abs() / 100);
    if (cents == 0) return text;
    if (cents < 0) return '−$text';
    return signed ? '+$text' : text;
  }

  /// Parses "12", "12,5", "12.50", "1.234,56", "1,234.56" into cents.
  /// Returns null unless it's a positive amount.
  static int? parse(String input) {
    var s = input.replaceAll(RegExp('[^0-9.,]'), '');
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    // The last separator is the decimal one when followed by 1-2 digits.
    final decimalAt = lastComma > lastDot ? lastComma : lastDot;
    if (decimalAt != -1 && s.length - decimalAt - 1 <= 2) {
      s = '${s.substring(0, decimalAt).replaceAll(RegExp('[.,]'), '')}.${s.substring(decimalAt + 1)}';
    } else {
      s = s.replaceAll(RegExp('[.,]'), '');
    }
    final value = double.tryParse(s);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }
}

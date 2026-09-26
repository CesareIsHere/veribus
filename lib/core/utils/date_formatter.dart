import 'package:intl/intl.dart';

/// Locale-aware date helpers (the locale comes from the active app language).
abstract final class DateFormatter {
  static String date(DateTime? date) => date == null ? '--' : DateFormat.yMd().format(date.toLocal());

  static String dateTime(DateTime? date) => date == null ? '--' : DateFormat.yMd().add_Hm().format(date.toLocal());
}

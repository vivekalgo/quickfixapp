import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatIsoString(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      return formatShortDate(parsed);
    } catch (_) {
      return isoString;
    }
  }

  static String formatIsoStringToTime(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      return formatTime(parsed);
    } catch (_) {
      return isoString;
    }
  }
}


class DateTimeHelper {
  static String getLocalTimeISOString() {
    return DateTime.now().toUtc().toIso8601String();
  }
  
  static String toLocalISOString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static DateTime getLocalTime() {
    return DateTime.now().toLocal();
  }
}



class DateTimeHelper {
  static String getLocalTimeISOString() {
    return DateTime.now().toLocal().toIso8601String();
  }
  
  static String toLocalISOString(DateTime dateTime) {
    return dateTime.toLocal().toIso8601String();
  }

  static DateTime getLocalTime() {
    return DateTime.now().toLocal();
  }
}


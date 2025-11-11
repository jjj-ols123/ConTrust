
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

  static DateTime? parseToLocal(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toLocal();
    }

    final parsedWithZ = DateTime.tryParse('${value}Z');
    return parsedWithZ?.toLocal();
  }
}


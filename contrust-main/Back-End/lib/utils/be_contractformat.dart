import 'package:flutter/material.dart';

class ContractStyle {
  static String Function(String)? textResolver;

  static bool Function(int)? itemRowVisibilityChecker;
  static bool Function(int)? milestoneRowVisibilityChecker;

  static void setTextResolver(String Function(String) resolver) {
    textResolver = resolver;
  }

  static void clearTextResolver() {
    textResolver = null;
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
             '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

   static String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }



  static void setItemRowVisibilityChecker(bool Function(int) checker) {
    itemRowVisibilityChecker = checker;
  }

  static void clearItemRowVisibilityChecker() {
    itemRowVisibilityChecker = null;
  }

  static bool shouldShowItemRow(int rowNumber) {
    return itemRowVisibilityChecker != null
        ? itemRowVisibilityChecker!(rowNumber)
        : true;
  }

  static void setMilestoneRowVisibilityChecker(bool Function(int) checker) {
    milestoneRowVisibilityChecker = checker;
  }

  static void clearMilestoneRowVisibilityChecker() {
    milestoneRowVisibilityChecker = null;
  }

  static bool shouldShowMilestoneRow(int rowNumber) {
    return milestoneRowVisibilityChecker != null
        ? milestoneRowVisibilityChecker!(rowNumber)
        : true;
  }

  static Widget sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  static Widget paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          textResolver != null ? textResolver!(text) : text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      );

  static Widget infoBlock(List<String> lines) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((t) => paragraph(textResolver != null ? textResolver!(t) : t))
            .toList(),
      );

  static Widget bulletList(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          textResolver != null ? textResolver!(item) : item,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );

  static Widget numberedList(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final text =
              textResolver != null ? textResolver!(items[i]) : items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ', style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          );
        }),
      );

  static Widget signatureBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SIGNATURES:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('CONTRACTOR: _________________    DATE: _________________'),
          Text('[Contractor Name]'),
          SizedBox(height: 12),
          Text('CLIENT: _________________    DATE: _________________'),
          Text('[Client Name]'),
          SizedBox(height: 12),
          Text('WITNESS: _________________    DATE: _________________'),
          Text('[Witness Name]'),
        ],
      );

  static String getFieldValue(Map<String, String> fieldValues, String key) {
    return fieldValues[key]?.isNotEmpty == true
        ? fieldValues[key]!
        : '____________';
  }

  //for the time and materials contract
    static double parseMoney(String? s) {
    if (s == null) return 0.0;
    final cleaned = s.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double parsePercent(String? s) {
    if (s == null) return 0.0;
    final raw = s.trim();
    if (raw.isEmpty) return 0.0;
    final cleaned = raw.replaceAll('%', '').replaceAll(',', '');
    final v = double.tryParse(cleaned) ?? 0.0;
    if (v <= 0) return 0.0;

    if (cleaned.contains('.')) {
      return v; 
    } else {
      return v / 100.0; 
    }
  }

  static double computeSubtotal(Map<String, String> fieldValues) {
    final explicit = parseMoney(fieldValues['Payment.Subtotal']);
    if (explicit > 0) return explicit;
    final itemCount = int.tryParse(fieldValues['ItemCount'] ?? '') ?? 3;
    double sum = 0.0;
    for (int i = 1; i <= itemCount; i++) {
      final sub = parseMoney(fieldValues['Item.$i.Subtotal']);
      if (sub > 0) {
        sum += sub;
      } else {
        final price = parseMoney(fieldValues['Item.$i.Price']);
        final qty = parseMoney(fieldValues['Item.$i.Quantity']);
        if (price > 0 && qty > 0) sum += price * qty;
      }
    }
    return sum;
  }
}

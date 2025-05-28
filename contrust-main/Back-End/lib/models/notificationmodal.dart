class NotificationModel {
  final String id;
  final String headline;
  final Map<String, dynamic> information;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.headline,
    required this.information,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['notification_id'],
      headline: map['headline'] ?? '',
      information: Map<String, dynamic>.from(map['extra_data'] ?? {}),
      isRead: map['is_read'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

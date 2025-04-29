import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> createNotification({
    required String? receiverId,
    required String receiverType,
    required String senderId,
    required String senderType,
    required String type,
    required String message,
    Map<String, dynamic>? information,
  }) async {
    try {
      final notificationData = {
        'receiver_id': receiverId,
        'receiver_type': receiverType,
        'sender_id': senderId,
        'sender_type': senderType,
        'type': type,
        'message': message,
        'extra_data': information ?? {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('Notifications')
          .insert(notificationData)
          .select();

      if (response.isEmpty) {
        throw Exception('Failed to create notification');
      }
    } catch (e) {
      throw Exception('Notification error: ${e.toString()}');
    }
  }

  Stream<List<Map<String, dynamic>>> listenNotification(String receiverId) {
    return supabase
        .from('Notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('receiver_id', receiverId)
        .order('created_at', ascending: false);
  }

  Future<void> readNotification(String notificationId) async {
    try {
      await supabase
          .from('Notifications')
          .update({'is_read': true}).eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark as read: ${e.toString()}');
    }
  }
}

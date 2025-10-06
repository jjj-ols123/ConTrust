import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //For Both Users

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
        'headline': type,
        'information': {
          ...?information,
          'message': message,
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('Notifications')
          .insert(notificationData)
          .select();

      if (response.isEmpty) {
        throw Exception('Failed to create notification');
      }
    } catch (e) {
      throw Exception('Notification error');
    }
  }

   Future<List<Map<String, dynamic>>> getNotifications(String receiverId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select()
          .eq('receiver_id', receiverId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications(
      String receiverId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select()
          .eq('receiver_id', receiverId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationsByType(
    String receiverId,
    String type,
  ) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select()
          .eq('receiver_id', receiverId)
          .eq('headline', type)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('Notifications')
          .update({'is_read': true}).eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark as read');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('Notifications')
          .delete()
          .eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  Stream<List<Map<String, dynamic>>> listenToNotifications(String receiverId) {
    return _supabase
        .from('Notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('receiver_id', receiverId)
        .order('created_at', ascending: false)
        .distinct();
  }

  Future<int> getUnreadCount(String receiverId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select('notification_id')
          .eq('receiver_id', receiverId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  //For Contractors

  Future<void> createProjectNotification({
    required String receiverId,
    required String receiverType,
    required String senderId,
    required String senderType,
    required String projectId,
    required String type,
    required String message,
  }) async {
    await createNotification(
      receiverId: receiverId,
      receiverType: receiverType,
      senderId: senderId,
      senderType: senderType,
      type: type,
      message: message,
      information: {'project_id': projectId},
    );
  }

  Future<void> createContractNotification({
    required String receiverId,
    required String receiverType,
    required String senderId,
    required String senderType,
    required String contractId,
    required String type,
    required String message,
  }) async {
    await createNotification(
      receiverId: receiverId,
      receiverType: receiverType,
      senderId: senderId,
      senderType: senderType,
      type: type,
      message: message,
      information: {'contract_id': contractId},
    );
  }

  Future<void> createBidNotification({
    required String receiverId,
    required String receiverType,
    required String senderId,
    required String senderType,
    required String bidId,
    required String projectId,
    required String type,
    required String message,
  }) async {
    await createNotification(
      receiverId: receiverId,
      receiverType: receiverType,
      senderId: senderId,
      senderType: senderType,
      type: type,
      message: message,
      information: {
        'bid_id': bidId,
        'project_id': projectId,
      },
    );
  }

  //For Contractees

  Future<void> notifyNewBid({
    required String contracteeId,
    required String contractorId,
    required String projectId,
    required String bidId,
    required double bidAmount,
  }) async {
    await createBidNotification(
      receiverId: contracteeId,
      receiverType: 'contractee',
      senderId: contractorId,
      senderType: 'contractor',
      bidId: bidId,
      projectId: projectId,
      type: 'new_bid',
      message:
          'You have received a new bid of \$${bidAmount.toStringAsFixed(2)} for your project.',
    );
  }

  Future<void> notifyBidAccepted({
    required String contractorId,
    required String contracteeId,
    required String projectId,
    required String bidId,
  }) async {
    await createBidNotification(
      receiverId: contractorId,
      receiverType: 'contractor',
      senderId: contracteeId,
      senderType: 'contractee',
      bidId: bidId,
      projectId: projectId,
      type: 'bid_accepted',
      message: 'Congratulations! Your bid has been accepted.',
    );
  }
}

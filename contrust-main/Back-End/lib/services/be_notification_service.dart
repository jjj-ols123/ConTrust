import 'package:backend/services/be_fetchservice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<List<Map<String, dynamic>>> getUnreadNotifications(String receiverId) async {
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
          .update({'is_read': true})
          .eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark as read: ${e.toString()}');
    }
  }

  Future<void> markAllAsRead(String receiverId) async {
    try {
      await _supabase
          .from('Notifications')
          .update({'is_read': true})
          .eq('receiver_id', receiverId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all as read: ${e.toString()}');
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

  Future<void> deleteAllNotifications(String receiverId) async {
    try {
      await _supabase
          .from('Notifications')
          .delete()
          .eq('receiver_id', receiverId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: ${e.toString()}');
    }
  }

  Future<void> deleteOldNotifications(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      await _supabase
          .from('Notifications')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
    } catch (e) {
      throw Exception('Failed to delete old notifications: ${e.toString()}');
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

  Future<int> getTotalCount(String receiverId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select('notification_id')
          .eq('receiver_id', receiverId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getNotificationStatsByType(String receiverId) async {
    try {
      final response = await _supabase
          .from('Notifications')
          .select('headline')
          .eq('receiver_id', receiverId);

      Map<String, int> stats = {};
      for (var notification in response) {
        String type = notification['headline'] ?? 'unknown';
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

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
      message: 'You have received a new bid of \$${bidAmount.toStringAsFixed(2)} for your project.',
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

  Future<void> notifyProjectCompleted({
    required String receiverId,
    required String receiverType,
    required String senderId,
    required String senderType,
    required String projectId,
  }) async {
    await createProjectNotification(
      receiverId: receiverId,
      receiverType: receiverType,
      senderId: senderId,
      senderType: senderType,
      projectId: projectId,
      type: 'project_completed',
      message: 'The project has been marked as completed.',
    );
  }

  Future<void> notifyContractor({
    required String contractorId,
    required String contracteeId,
    required String projectId,
  }) async {
    try {
      final contracteeData = await FetchService().fetchContracteeData(contracteeId);
      final contracteeName = contracteeData?['full_name'] ?? 'A contractee';

      await NotificationService().createNotification(
        receiverId: contractorId,
        receiverType: 'contractor',
        senderId: contracteeId,
        senderType: 'contractee',
        type: 'Hiring Request',
        message: '$contracteeName wants to hire your construction firm!',
        information: {
          'contractee_id': contracteeId,
          'full_name': contracteeName,
          'project_id': projectId,
          'action': 'hire_request',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }
  
}

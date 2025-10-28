import 'dart:convert';

import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

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
    try {
      if (type.toLowerCase() == 'new bid' && receiverType.toLowerCase() == 'contractee') {
        final bidRow = await _supabase
            .from('Bids')
            .select('bid_amount, contractor_id, project_id')
            .eq('bid_id', bidId)
            .maybeSingle();

        final double bidAmount = bidRow != null && bidRow['bid_amount'] != null
            ? (bidRow['bid_amount'] as num).toDouble()
            : 0.0;

        final String contractorId = bidRow != null && bidRow['contractor_id'] != null
            ? bidRow['contractor_id'].toString()
            : senderId;

        final String projId = bidRow != null && bidRow['project_id'] != null
            ? bidRow['project_id'].toString()
            : projectId;

        await notifyNewBid(
          contracteeId: receiverId,
          contractorId: contractorId,
          projectId: projId,
          bidId: bidId,
          bidAmount: bidAmount,
        );
        return;
      }

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
    } catch (e, st) {
      await _errorService.logError(
        errorMessage: 'Failed to create bid notification: ',
        module: 'Notification Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'createBidNotification',
          'receiver_id': receiverId,
          'sender_id': senderId,
          'bid_id': bidId,
          'project_id': projectId,
          'stack': st.toString(),
        },
      );
    }
  }

  //For Contractees

  Future<void> notifyNewBid({
    required String contracteeId,
    required String contractorId,
    required String projectId,
    required String bidId,
    required double bidAmount,
  }) async {
    try {

      final proj = await _supabase
          .from('Projects')
          .select('title')
          .eq('project_id', projectId)
          .maybeSingle();
      final projectTitle = proj?['title'] ?? 'Project';

      final contractor = await _supabase
          .from('Contractor')
          .select('firm_name, profile_photo')
          .eq('contractor_id', contractorId)
          .maybeSingle();
      final contractorName = contractor?['firm_name'] ?? 'Contractor';
      final contractorPhoto = contractor?['profile_photo'] ?? '';

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toIso8601String();
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final existing = await _supabase
          .from('Notifications')
          .select()
          .eq('receiver_id', contracteeId)
          .eq('headline', 'Project Bids Update')
          .eq('information->>project_id', projectId)
          .gte('created_at', start)
          .lt('created_at', end)
          .maybeSingle();

      if (existing != null) {

        var info = existing['information'];
        if (info is String) info = jsonDecode(info);
        final Map<String, dynamic> infoMap = Map<String, dynamic>.from(info ?? {});
        final List<Map<String, dynamic>> bids = List<Map<String, dynamic>>.from(infoMap['bids'] ?? []);
        bids.add({
          'bid_id': bidId,
          'contractor_name': contractorName,
          'contractor_photo': contractorPhoto,
          'bid_amount': bidAmount,
          'created_at': DateTime.now().toIso8601String(),
        });
        infoMap['bids'] = bids;
        infoMap['count'] = bids.length;
        infoMap['project_id'] = projectId;
        infoMap['project_title'] = projectTitle;
       infoMap['message'] = 'Your project "$projectTitle" has received ${bids.length} bids today';

        await _supabase
            .from('Notifications')
            .update({
              'information': infoMap,
            })
            .eq('notification_id', existing['notification_id']);
      } else {
        final infoMap = {
          'project_id': projectId,
          'project_title': projectTitle,
          'bids': [
            {
              'bid_id': bidId,
              'contractor_name': contractorName,
              'contractor_photo': contractorPhoto,
              'bid_amount': bidAmount,
              'created_at': DateTime.now().toIso8601String(),
            }
          ],
          'count': 1,
        };

        await createNotification(
          receiverId: contracteeId,
          receiverType: 'contractee',
          senderId: contractorId,
          senderType: 'contractor',
          type: 'Project Bids Update',
          message: 'Your project "$projectTitle" has received 1 bid today',
          information: infoMap,
        );
      }
    } catch (e, st) {
      await _errorService.logError(
        errorMessage: 'Failed to compile bid notification: ',
        module: 'Notification Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'notifyNewBid',
          'project_id': projectId,
          'contractee_id': contracteeId,
          'contractor_id': contractorId,
          'bid_id': bidId,
          'stack': st.toString(),
        },
      );
    }
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

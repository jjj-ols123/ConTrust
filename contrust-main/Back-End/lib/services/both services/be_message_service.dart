import 'package:backend/services/superadmin%20services/auditlogs_service.dart';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getOrCreateChatRoom({
    required String contractorId,
    required String contracteeId,
    required String projectId,
  }) async {
    try {
      final existingChatroom = await _supabase
          .from('ChatRoom')
          .select('chatroom_id')
          .eq('contractor_id', contractorId)
          .eq('contractee_id', contracteeId)
          .eq('project_id', projectId)
          .maybeSingle();

      if (existingChatroom != null) {
        return existingChatroom['chatroom_id'] as String?;
      }

      final response = await _supabase
          .from('ChatRoom')
          .insert({
            'contractor_id': contractorId,
            'contractee_id': contracteeId,
            'project_id': projectId,
          })
          .select('chatroom_id')
          .single();

      await SuperAdminAuditService().logAuditEvent(
        action: 'CHATROOM_CREATED',
        details:
            'Chat room created between $contractorId and $contracteeId for project $projectId',
        category: 'Contract',
        metadata: {
          'contract_id': contracteeId,
          'contractor_id': contractorId,
          'chatroom_id': response['chatroom_id'],
        },
      );

      return response['chatroom_id'] as String?;
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to create chat room: $e',
        module: 'UI Message',
        severity: 'High',
        extraInfo: {
          'operation': 'Create Chat Room',
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchContracteeData(String contracteeId) async {
    try {
      final response = await _supabase
          .from('Contractee')
          .select('full_name, profile_photo')
          .eq('contractee_id', contracteeId)
          .single();
      final data = Map<String, dynamic>.from(response);
      
      if ((data['profile_photo'] == null || (data['profile_photo'] as String).isEmpty) && 
          _supabase.auth.currentUser?.id == contracteeId) {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          final googlePhoto = currentUser.userMetadata?['avatar_url'] ?? 
                             currentUser.userMetadata?['picture'];
          if (googlePhoto != null && googlePhoto.toString().isNotEmpty) {
            data['profile_photo'] = googlePhoto.toString();
          }
        }
      }
      
      return data;
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch contractee data: $e',
        module: 'Message Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractee Data',
          'contractee_id': contracteeId,
        },
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchContractorData(String contractorId) async {
    try {
      final response = await _supabase
          .from('Contractor')
          .select('firm_name, profile_photo')
          .eq('contractor_id', contractorId)
          .single();
      final data = Map<String, dynamic>.from(response);
      
      // Fallback: If profile_photo is missing/empty and this is the current user, try auth metadata (for Google sign-in)
      if ((data['profile_photo'] == null || (data['profile_photo'] as String).isEmpty) && 
          _supabase.auth.currentUser?.id == contractorId) {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          final googlePhoto = currentUser.userMetadata?['avatar_url'] ?? 
                             currentUser.userMetadata?['picture'];
          if (googlePhoto != null && googlePhoto.toString().isNotEmpty) {
            data['profile_photo'] = googlePhoto.toString();
          }
        }
      }
      
      return data;
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch contractor data: $e',
        module: 'Message Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Fetch Contractor Data',
          'contractor_id': contractorId,
        },
      );
      return null;
    }
  }

  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('Messages')
          .update({'is_read': true})
          .eq('chatroom_id', chatRoomId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to mark messages as read: $e',
        module: 'Message Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Mark Messages Read',
          'chatroom_id': chatRoomId,
          'user_id': userId,
        },
      );
    }
  }

  Future<int> getUnreadMessageCount({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('Messages')
          .select('msg_id')
          .eq('chatroom_id', chatRoomId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to get unread message count: $e',
        module: 'Message Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Unread Count',
          'chatroom_id': chatRoomId,
          'user_id': userId,
        },
      );
      return 0;
    }
  }

  Future<int> getTotalUnreadMessageCount(String userId) async {
    try {
      final response = await _supabase
          .from('Messages')
          .select('msg_id')
          .eq('receiver_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to get total unread message count: $e',
        module: 'Message Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Total Unread Count',
          'user_id': userId,
        },
      );
      return 0;
    }
  }
}

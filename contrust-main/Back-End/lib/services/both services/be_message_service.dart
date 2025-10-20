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
        errorMessage: 'Failed to create chat room: ',
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
}

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

      return response['chatroom_id'] as String?;
    } catch (e) {
      return null;
    }
  }
}

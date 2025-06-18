// ignore_for_file: avoid_print, file_names

import 'package:supabase_flutter/supabase_flutter.dart';

class GetUserData {

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String?> getContractorId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('Contractor')
          .select('contractor_id')
          .eq('contractor_id', user.id)
          .maybeSingle();

      return response?['contractor_id'].toString();
    } catch (error) {
      return null;
    }
  }

  Future<String?> getContracteeId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('Contractee')
          .select('contractee_id')
          .eq('contractee_id', user.id)
          .maybeSingle();

      return response?['contractee_id']?.toString();

    } catch (error) {
      return null;
    }
  }

  Future<String?> getCurrentUserType() async {
    final session = await Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    await Supabase.instance.client.auth.refreshSession();
    final user = Supabase.instance.client.auth.currentUser;

    final type = user?.userMetadata?['user_type'];
    return type?.toString();
  }

  Future<void> checkContracteeId(String userId) async {
    final response = await _supabase
        .from('Contractee')
        .select()
        .eq('contractee_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Contractee not found');
    }
  }

   Future<void> checkContractorId(String userId) async {
    final response = await _supabase
        .from('Contractor')
        .select()
        .eq('contractor_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Contractor not found');
    }
  }

    Future<String?>   getProjectId(String chatRoomId) async {
    final chatRoom = await _supabase
        .from('ChatRoom')
        .select('project_id')
        .eq('chatroom_id', chatRoomId)
        .maybeSingle();
    return chatRoom?['project_id'];
  }

  Future<Map<String, dynamic>?> getProjectInfo(String projectId) async {
    return await _supabase
        .from('Projects')
        .select('contract_started, contractor_agree, contractee_agree')
        .eq('project_id', projectId)
        .maybeSingle();
  }


}

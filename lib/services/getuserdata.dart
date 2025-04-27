// ignore_for_file: avoid_print, file_names

import 'package:supabase_flutter/supabase_flutter.dart';

//get user id
class GetUserId {
  Future<String?> getContractorId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('Contractor')
          .select('contractor_id')
          .eq('contractor_id', user.id)
          .maybeSingle();

      return response?['contractor_id'] as String?;
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
}

import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUnverifiedContractors() async {
    final response = await _supabase
        .from('Contractor')
        .select('contractor_id, firm_name, contact_number, created_at')
        .eq('verified', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<String>> getVerificationDocs(String contractorId) async {
    final response = await _supabase
        .from('Verification')
        .select('doc_url')
        .eq('contractor_id', contractorId);
    return (response as List).map((doc) => doc['doc_url'] as String).toList();
  }

  Future<void> verifyContractor(String contractorId, bool approve) async {
    await _supabase
        .from('Contractor')
        .update({'verified': approve})
        .eq('contractor_id', contractorId);

    await _supabase
        .from('Users')
        .update({'verified': approve})
        .eq('users_id', contractorId);
  }
}
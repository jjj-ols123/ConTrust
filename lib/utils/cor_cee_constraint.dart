import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> functionConstraint(String contractorId, String contracteeId) async {
  final response = await Supabase.instance.client
      .from('Projects')
      .select('project_id')
      .eq('contractor_id', contractorId)
      .eq('contractee_id', contracteeId)
      .inFilter('status', ['awaiting_contract', 'active'])
      .maybeSingle();
  return response != null;
}

Future<bool> hasAlreadyBid(String contractorId, String projectId) async {
  final response = await Supabase.instance.client
      .from('Bids')
      .select('bid_id')
      .eq('contractor_id', contractorId)
      .eq('project_id', projectId)
      .maybeSingle();
  return response != null;
}
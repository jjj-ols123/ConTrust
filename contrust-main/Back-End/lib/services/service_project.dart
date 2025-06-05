import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> finalizeContractAgreement({
  required String projectId,
  required String contractId,
  required String contractTypeId,
  required String contracteeId,
  required String contractorId,
  required Map<String, dynamic> terms, 
  required String contracteeSignature,
  required String contractorSignature,
}) async {
  final now = DateTime.now().toUtc().toIso8601String();

  await supabase
      .from('Projects')
      .update({'status': 'active'})
      .eq('project_id', projectId);

  await supabase
      .from('Contracts')
      .update({
        'status': 'active',
        'contractee_signature': contracteeSignature,
        'contractor_signature': contractorSignature,
        'signed_at': now,
        'updated_at': now,
        'terms': terms,
      })
      .eq('contract_id', contractId);

  await supabase
      .from('ContractDetails')
      .update({'contract_type_id': contractTypeId})
      .eq('contract_id', contractId);

  await supabase
      .from('ContractTypes')
      .update({'updated_at': now})
      .eq('contract_type_id', contractTypeId);
}
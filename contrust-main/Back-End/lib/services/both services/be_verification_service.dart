import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String?> submitContractorVerification({
    required String legalName,
    String? pcabLicenseNo,
    String? pcabQrText,
    String? permitLgu,
    String? permitNumber,
    String? permitQrText,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final payload = {
      'contractor_id': user.id,
      'legal_name_submitted': legalName,
      if (pcabLicenseNo != null && pcabLicenseNo.isNotEmpty) 'pcab_license_no': pcabLicenseNo,
      if (pcabQrText != null && pcabQrText.isNotEmpty) 'pcab_qr_text': pcabQrText,
      if (permitLgu != null && permitLgu.isNotEmpty) 'permit_lgu': permitLgu,
      if (permitNumber != null && permitNumber.isNotEmpty) 'permit_number': permitNumber,
      if (permitQrText != null && permitQrText.isNotEmpty) 'permit_qr_text': permitQrText,
    };

    final inserted = await _supabase
        .from('contractor_verifications')
        .insert(payload)
        .select('id')
        .maybeSingle();

    final verificationId = inserted?['id']?.toString();

    try {
      await _supabase.functions.invoke(
        'run-verification',
        body: {
          'verificationId': verificationId,
          'contractorId': user.id,
        },
      );
    } catch (_) {
      // 
    }

    return verificationId;
  }

  Future<Map<String, dynamic>?> getLatestVerification() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final row = await _supabase
        .from('contractor_verifications')
        .select()
        .eq('contractor_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row;
  }
}



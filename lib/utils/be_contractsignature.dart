import 'dart:typed_data';
import 'package:backend/services/both%20services/be_pdf_signature_service.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignatureCompletionHandler {
  
  static Future<void> onSignatureSaved(String contractId) async {
    try {
      await ContractPdfSignatureService.checkAndGenerateSignedPdf(contractId);
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<void> signContractWithPdfGeneration({
    required String contractId,
    required String userId,
    required Uint8List signatureBytes,
    required String userType,
  }) async {
    try {

      final contractData = await ContractService.getContractById(contractId);
      final isCustomContract = contractData['contract_type_id'] == 'd9d78420-7765-44d5-966c-6f0e0297c07d';

      if (isCustomContract) {
      
        await ContractService.signContract(
          contractId: contractId,
          userId: userId,
          signatureBytes: signatureBytes,
          userType: userType,
        );

        await Supabase.instance.client
            .from('Contracts')
            .update({'signed_pdf_url': contractData['pdf_url']})
            .eq('contract_id', contractId);
        return;  
      }

      await ContractService.signContract(
        contractId: contractId,
        userId: userId,
        signatureBytes: signatureBytes,
        userType: userType,
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      await onSignatureSaved(contractId);
    } catch (e) {
      rethrow;
    }
  }
}
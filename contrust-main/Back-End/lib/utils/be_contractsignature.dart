import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:backend/services/both services/be_pdf_signature_service.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignatureCompletionHandler {
  
  static Future<void> onSignatureSaved(String contractId) async {
    debugPrint('[SignHandler] onSignatureSaved called for contractId=$contractId');
    try {
      await ContractPdfSignatureService.checkAndGenerateSignedPdf(contractId);
      debugPrint('[SignHandler] checkAndGenerateSignedPdf completed in onSignatureSaved');
    } catch (e) {
      debugPrint('[SignHandler] ERROR in onSignatureSaved: $e');
      rethrow;
    }
  }
  
  static Future<void> signContractWithPdfGeneration({
    required String contractId,
    required String userId,
    required Uint8List signatureBytes,
    required String userType,
  }) async {
    debugPrint('[SignHandler] Starting signContractWithPdfGeneration for contractId=$contractId, userId=$userId, userType=$userType');

    try {
      final contractData = await ContractService.getContractById(contractId);
      debugPrint('[SignHandler] Fetched contract data: ${contractData.keys.join(', ')}');
      
      final isCustomContract = contractData['contract_type_id'] == 'd9d78420-7765-44d5-966c-6f0e0297c07d';
      debugPrint('[SignHandler] Is custom contract: $isCustomContract');

      if (isCustomContract) {
        debugPrint('[SignHandler] Handling custom contract signing');
      
        await ContractService.signContract(
          contractId: contractId,
          userId: userId,
          signatureBytes: signatureBytes,
          userType: userType,
        );
        debugPrint('[SignHandler] Custom contract signed successfully');

        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('[SignHandler] Delay completed, fetching updated contract');
        
        final updatedContractData = await ContractService.getContractById(contractId);
        debugPrint('[SignHandler] Updated contract data fetched');
        
        final contractorSigned = updatedContractData['contractor_signature_url'] != null &&
            (updatedContractData['contractor_signature_url'] as String).isNotEmpty;
        final contracteeSigned = updatedContractData['contractee_signature_url'] != null &&
            (updatedContractData['contractee_signature_url'] as String).isNotEmpty;
        
        debugPrint('[SignHandler] Contractor signed: $contractorSigned, Contractee signed: $contracteeSigned');
        
        if (contractorSigned && contracteeSigned) {
          debugPrint('[SignHandler] Both parties signed - updating signed_pdf_url');
          final hasSignedPdf = updatedContractData['signed_pdf_url'] != null &&
               (updatedContractData['signed_pdf_url'] as String).isNotEmpty;

          if (!hasSignedPdf) {
            await Supabase.instance.client
                .from('Contracts')
                .update({'signed_pdf_url': updatedContractData['pdf_url']})
                .eq('contract_id', contractId);
            debugPrint('[SignHandler] signed_pdf_url updated for custom contract');
          } else {
            debugPrint('[SignHandler] signed_pdf_url already exists');
          }
        } else {
          debugPrint('[SignHandler] Not both parties signed yet - no signed_pdf_url update');
        }
        return;  
      }

      debugPrint('[SignHandler] Handling standard contract signing');
      await ContractService.signContract(
        contractId: contractId,
        userId: userId,
        signatureBytes: signatureBytes,
        userType: userType,
      );
      debugPrint('[SignHandler] Standard contract signed successfully');
      
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('[SignHandler] Delay completed, calling checkAndGenerateSignedPdf');
      
      await onSignatureSaved(contractId);
      debugPrint('[SignHandler] checkAndGenerateSignedPdf completed');
    } catch (e) {
      debugPrint('[SignHandler] ERROR in signContractWithPdfGeneration: $e');
      rethrow;
    }
  }
}
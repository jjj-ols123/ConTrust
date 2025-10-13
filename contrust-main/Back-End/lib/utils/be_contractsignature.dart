import 'dart:typed_data';
import 'package:backend/services/both%20services/be_pdf_signature_service.dart';
import 'package:backend/services/both services/be_contract_service.dart';

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
    await ContractService.signContract(
      contractId: contractId,
      userId: userId,
      signatureBytes: signatureBytes,
      userType: userType,
    );
    
    await onSignatureSaved(contractId);
  }
}
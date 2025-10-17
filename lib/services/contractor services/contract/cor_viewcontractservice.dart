// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:backend/utils/be_contractsignature.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ViewContractService {
  static Future<Map<String, dynamic>> loadContract(String contractId) async {
    try {
      return await ContractService.getContractById(contractId);
    } catch (e) {
      throw Exception('Error loading contract: $e');
    }
  }

  static Future<dynamic> downloadContract({
    required Map<String, dynamic> contractData,
    required BuildContext context,
  }) async {
    String? pdfUrl = contractData['pdf_url'] as String?;
    
    if (pdfUrl == null || pdfUrl.isEmpty) {
      final contractorId = contractData['contractor_id'] as String?;
      final projectId = contractData['project_id'] as String?;
      final contracteeId = contractData['contractee_id'] as String?;
      
      if (contractorId != null && projectId != null && contracteeId != null) {
        pdfUrl = '$contractorId/${projectId}_$contracteeId.pdf';
      }
    }
    
    if (pdfUrl == null) {
      throw Exception('No PDF contract available');
    }

    try {
      final pdfBytes = await ContractPdfService.downloadContractPdf(pdfUrl);
      final fileName = 'Contract_${contractData['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
      final result = await ContractPdfService.saveToDevice(pdfBytes, fileName);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signContract({
    required String contractId,
    required String contractorId,
    required Uint8List signatureBytes,
  }) async {
    try {
      await SignatureCompletionHandler.signContractWithPdfGeneration(
        contractId: contractId,
        userId: contractorId,
        signatureBytes: signatureBytes,
        userType: 'contractor',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getSignedUrl(String signaturePath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('signatures')
          .createSignedUrl(signaturePath, 60 * 60);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getSignedContractUrl(String contractPath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('contracts')
          .createSignedUrl(contractPath, 60 * 60 * 24);
      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  static String? getPdfUrl(Map<String, dynamic> contractData) {
    String? pdfUrl = contractData['pdf_url'] as String?;
    
    if (pdfUrl == null || pdfUrl.isEmpty) {
      final contractorId = contractData['contractor_id'] as String?;
      final projectId = contractData['project_id'] as String?;
      final contracteeId = contractData['contractee_id'] as String?;
      
      if (contractorId != null && projectId != null && contracteeId != null) {
        pdfUrl = '$contractorId/${projectId}_$contracteeId.pdf';
      }
    }
    
    return pdfUrl;
  }

  static Future<String?> getPdfSignedUrl(Map<String, dynamic> contractData) async {
    final signedPdfUrl = contractData['signed_pdf_url'] as String?;

    if (signedPdfUrl != null && signedPdfUrl.isNotEmpty) {
      try {
        final signedUrl = await Supabase.instance.client.storage
            .from('contracts')
            .createSignedUrl(signedPdfUrl, 60 * 60 * 24);
        return signedUrl;
      } catch (e) {
        return null;
      }
    }
    
    final pdfPath = getPdfUrl(contractData);
    
    if (pdfPath == null) {
      return null;
    }
    
    try {
      final fileExists = await checkFileExists(pdfPath);
      if (!fileExists) {
        return null;
      }
      
      final signedUrl = await Supabase.instance.client.storage
          .from('contracts')
          .createSignedUrl(pdfPath, 60 * 60 * 24); 
      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> checkFileExists(String filePath) async {
    try {
      final response = await Supabase.instance.client.storage
          .from('contracts')
          .list(path: filePath.contains('/') ? filePath.split('/').first : '');
      
      return response.any((file) => file.name == filePath.split('/').last);
    } catch (e) {
      return false;
    }
  }

  static bool canSignContract(Map<String, dynamic>? contractData) {
    if (contractData == null) return false;
    final status = contractData['status'] as String?;
    return status != null && status != 'signed';
  }

  static String generateFileName(Map<String, dynamic> contractData) {
    final title = contractData['title'] as String?;
    return 'Contract_${title?.replaceAll(' ', '_') ?? 'Document'}.pdf';
  }

  static bool isSignatureValid(Uint8List? signatureBytes) {
    return signatureBytes != null && signatureBytes.isNotEmpty;
  }

  static String formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  static Future<void> handleDownload({
    required Map<String, dynamic> contractData,
    required BuildContext context,
  }) async {
    try {
      final result = await downloadContract(
        contractData: contractData,
        context: context,
      );

      if (kIsWeb) {
        ConTrustSnackBar.success(context, 'Contract download started');
      } else if (result is File) {
        ConTrustSnackBar.success(context, 'Contract downloaded to: ${result.path}');
      } else {
        ConTrustSnackBar.success(context, 'Contract downloaded successfully');
      }
    } catch (e) {
      ConTrustSnackBar.error(context, e.toString());
    }
  }

  static Future<bool> handleSignature({
    required String contractId,
    required String contractorId,
    required Uint8List? signatureBytes,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    if (!isSignatureValid(signatureBytes)) {
      ConTrustSnackBar.warning(context, 'Please provide a signature');
      return false;
    }

    try {
      await signContract(
        contractId: contractId,
        contractorId: contractorId,
        signatureBytes: signatureBytes!,
      );

      ConTrustSnackBar.success(context, 'Signature saved!');
      onSuccess();
      return true;
    } catch (e) {
      ConTrustSnackBar.error(context, e.toString());
      return false;
    }
  }
}

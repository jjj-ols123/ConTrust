// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:backend/utils/be_contractsignature.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class ViewContractService {

  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  static Future<Map<String, dynamic>> loadContract(String contractId, {String? contractorId}) async {
    try {
      return await ContractService.getContractById(contractId, contractorId: contractorId);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to load contract: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Load Contract',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      throw Exception('Error loading contract:');
    }
  }

  static Future<dynamic> downloadContract({
    required Map<String, dynamic> contractData,
    required BuildContext context,
  }) async {
    try {
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
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download contract: ',
        module: 'View Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Contract',
          'contract_id': contractData['contract_id'],
        },
      );
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
      await _errorService.logError(
        errorMessage: 'Failed to sign contract: ',
        module: 'View Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Sign Contract',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
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
      await _errorService.logError(
        errorMessage: 'Failed to get signed URL: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Signed URL',
          'signature_path': signaturePath,
        },
      );
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
      await _errorService.logError(
        errorMessage: 'Failed to get signed contract URL: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get Signed Contract URL',
          'contract_path': contractPath,
        },
      );
      return null;
    }
  }

  static String? getPdfUrl(Map<String, dynamic> contractData) {
    try {
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
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to get PDF URL: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get PDF URL',
        },
      );
      return null;
    }
  }

  static Future<String?> getPdfSignedUrl(Map<String, dynamic> contractData) async {
    try {
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
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get PDF signed URL:',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Get PDF Signed URL',
        },
      );
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
      await _errorService.logError(
        errorMessage: 'Failed to check file exists: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Check File Exists',
          'file_path': filePath,
        },
      );
      return false;
    }
  }

  static bool canSignContract(Map<String, dynamic>? contractData) {
    try {
      if (contractData == null) return false;
      final status = contractData['status'] as String?;
      return status != null && status != 'signed';
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to check if can sign contract: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Can Sign Contract',
        },
      );
      return false;
    }
  }

  static String generateFileName(Map<String, dynamic> contractData) {
    try {
      final title = contractData['title'] as String?;
      return 'Contract_${title?.replaceAll(' ', '_') ?? 'Document'}.pdf';
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to generate file name:',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Generate File Name',
        },
      );
      return 'Contract_Document.pdf';
    }
  }

  static bool isSignatureValid(Uint8List? signatureBytes) {
    try {
      return signatureBytes != null && signatureBytes.isNotEmpty;
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to check signature validity: ',
        module: 'View Contract Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Is Signature Valid',
        },
      );
      return false;
    }
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
      } else {
        try {
          final filePath = result?.path ?? '';
          if (filePath.isNotEmpty) {
            ConTrustSnackBar.success(context, 'Contract downloaded to: $filePath');
          } else {
            ConTrustSnackBar.success(context, 'Contract downloaded successfully');
          }
        } catch (_) {
          ConTrustSnackBar.success(context, 'Contract downloaded successfully');
        }
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to handle download: ',
        module: 'View Contract Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Handle Download',
          'contract_id': contractData['contract_id'],
        },
      );
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
    try {
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
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to handle signature: ',
        module: 'View Contract Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Handle Signature',
          'contract_id': contractId,
          'contractor_id': contractorId,
        },
      );
      ConTrustSnackBar.error(context, e.toString());
      return false;
    }
  }
}

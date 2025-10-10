// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_contract_service.dart';
import 'package:backend/services/both services/be_contract_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:io';

class ViewContractService {
  static Future<Map<String, dynamic>> loadContract(String contractId) async {
    try {
      return await ContractService.getContractById(contractId);
    } catch (e) {
      throw Exception('Error loading contract: $e');
    }
  }

  static Future<File> downloadContract({
    required Map<String, dynamic> contractData,
    required BuildContext context,
  }) async {
    final pdfUrl = contractData['pdf_url'] as String?;
    
    if (pdfUrl == null) {
      throw Exception('No PDF contract available');
    }

    try {
      final pdfBytes = await ContractPdfService.downloadContractPdf(pdfUrl);
      final fileName = 'Contract_${contractData['title']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
      final file = await ContractPdfService.saveToDevice(pdfBytes, fileName);
      
      return file;
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
      await ContractService.signContract(
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
          .from('contracts')
          .createSignedUrl(signaturePath, 60 * 60); 
      return signedUrl;
    } catch (e) {
      return null;
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

  static void showSuccessMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static void showErrorMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void showWarningMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static String formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'signed':
        return Colors.purple;
      case 'active':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'under_review':
        return Icons.visibility;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'signed':
        return Icons.verified;
      case 'active':
        return Icons.play_circle;
      default:
        return Icons.info;
    }
  }

  static Future<void> handleDownload({
    required Map<String, dynamic> contractData,
    required BuildContext context,
  }) async {
    try {
      final file = await downloadContract(
        contractData: contractData,
        context: context,
      );
      
      showSuccessMessage(
        context,
        'Contract downloaded to: ${file.path}',
      );
    } catch (e) {
      showErrorMessage(context, e.toString());
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
      showWarningMessage(context, 'Please provide a signature');
      return false;
    }

    try {
      await signContract(
        contractId: contractId,
        contractorId: contractorId,
        signatureBytes: signatureBytes!,
      );
      
      showSuccessMessage(context, 'Signature saved!');
      onSuccess();
      return true;
    } catch (e) {
      showErrorMessage(context, e.toString());
      return false;
    }
  }
}

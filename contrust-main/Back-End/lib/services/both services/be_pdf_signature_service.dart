// ignore_for_file: file_names

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:backend/contract_templates/TimeandMaterialsPDF.dart';
import 'package:backend/contract_templates/LumpSumPDF.dart';
import 'package:backend/contract_templates/CostPlusPDF.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class ContractPdfSignatureService {
  static final _supabase = Supabase.instance.client;
  static final SuperAdminAuditService _auditService = SuperAdminAuditService();
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  static Future<Uint8List> generateSignedPdf({
    required Map<String, dynamic> contractData,
    required Map<String, String> fieldValues,
    Uint8List? contractorSignature,
    Uint8List? contracteeSignature,
  }) async {
    try {
      final contractTypeId = contractData['contract_type_id'] as String?;
      
      if (contractTypeId == null) {
        throw Exception('Contract type ID is missing');
      }
      
      final contractTypeData = await _supabase
          .from('ContractTypes')
          .select('template_name')
          .eq('contract_type_id', contractTypeId)
          .single();
      
      final contractType = contractTypeData['template_name'] as String?;
      
      if (contractType == null) {
        throw Exception('Contract type not found for ID: $contractTypeId');
      }
      
      List<pw.Widget> pdfWidgets;
      switch (contractType.toLowerCase()) {
        case 'time and materials contract':
          pdfWidgets = TimeAndMaterialsPDF.buildTimeAndMaterialsPdf(
            fieldValues,
            contractorSignature: contractorSignature,
            contracteeSignature: contracteeSignature,
          );
          break;
        case 'lump sum contract':
          pdfWidgets = LumpSumPDF.buildLumpSumPdf(
            fieldValues,
            contractorSignature: contractorSignature,
            contracteeSignature: contracteeSignature,
          );
          break;
        case 'cost-plus contract':
          pdfWidgets = CostPlusPDF.buildCostPlusPdf(
            fieldValues,
            contractorSignature: contractorSignature,
            contracteeSignature: contracteeSignature,
          );
          break;
        default:
          throw Exception('Unsupported contract type: $contractType');
      }
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => pdfWidgets,
        ),
      );

      final pdfBytes = await pdf.save();
      return pdfBytes;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to generate signed PDF:',
        module: 'Contract PDF Signature Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Generate Signed PDF',
          'contract_type_id': contractData['contract_type_id'],
        },
      );
      rethrow;
    }
  }

  static Future<Uint8List?> downloadSignature(String? signaturePath) async {
    try {
      if (signaturePath == null || signaturePath.isEmpty) return null;
      
      if (signaturePath.startsWith('http')) {
        return null;
      }
      
      final response = await _supabase.storage
          .from('signatures')
          .download(signaturePath);
      
      return response;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download signature: ',
        module: 'Contract PDF Signature Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Download Signature',
          'signature_path': signaturePath,
        },
      );
      return null;
    }
  }

  static Future<String> createSignedContractPdf({
    required String contractId,
  }) async {
    try {
      print('[ContractPdfSignatureService] Preparing signed PDF for contract: $contractId');
      final contractData = await ContractService.getContractById(contractId);

      final contractorId = contractData['contractor_id'] as String?;
      if (contractorId == null) {
        throw Exception('Contractor ID not found in contract data');
      }

      final rawFieldValues = contractData['field_values'];
      final fieldValues = rawFieldValues is Map
          ? Map<String, String>.from(rawFieldValues.map((key, value) => MapEntry(key.toString(), value.toString())))
          : <String, String>{};

      final contractorSignature = await downloadSignature(
        contractData['contractor_signature_url'],
      );
      final contracteeSignature = await downloadSignature(
        contractData['contractee_signature_url'],
      );

      final pdfBytes = await generateSignedPdf(
        contractData: contractData,
        fieldValues: fieldValues,
        contractorSignature: contractorSignature,
        contracteeSignature: contracteeSignature,
      );

      print('[ContractPdfSignatureService] Generated PDF bytes length: ${pdfBytes.length}');
      final fileName = 'signed_${contractId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$contractorId/signed/$contractId/$fileName';
      print('[ContractPdfSignatureService] Uploading signed PDF to path: $filePath');

      try {
        await _supabase.storage
            .from('contracts')
            .uploadBinary(filePath, pdfBytes, fileOptions: const FileOptions(upsert: true));
        print('[ContractPdfSignatureService] Upload succeeded for $filePath');
      } catch (e) {
        print('[ContractPdfSignatureService] Upload failed for $filePath: $e');
        rethrow;
      }

      try {
        await _supabase.storage.from('contracts').download(filePath);
        print('[ContractPdfSignatureService] Verified download succeeds for $filePath');
      } catch (e) {
        print('[ContractPdfSignatureService] Download verification failed for $filePath: $e');
        throw Exception('Uploaded signed PDF but could not verify download: $e');
      } 

      try {
        final testSignedUrl = await _supabase.storage
            .from('contracts')
            .createSignedUrl(filePath, 300); 
        print('[ContractPdfSignatureService] Created signed URL for $filePath: ${testSignedUrl.isNotEmpty}');

        if (testSignedUrl.isEmpty) {
          throw Exception('Failed to create signed URL for uploaded file');
        }

        final response = await http.get(Uri.parse(testSignedUrl));
        print('[ContractPdfSignatureService] Signed URL response status: ${response.statusCode}, length: ${response.contentLength}');
        if (response.statusCode != 200) {
          throw Exception('Signed URL returned status ${response.statusCode}');
        }

        if (response.contentLength == null || response.contentLength! <= 0) {
          throw Exception('Signed URL returned empty content');
        }

        if (response.contentLength != pdfBytes.length) {
          throw Exception('Signed URL content size (${response.contentLength}) doesn\'t match uploaded size (${pdfBytes.length})');
        }

      } catch (e) {
        throw Exception('Signed PDF uploaded and verified but signed URL access failed: $e');
      }
      try {
        await _supabase
            .from('Contracts')
            .update({
              'signed_pdf_url': filePath,
            })
            .eq('contract_id', contractId);

        final approvedMessage = await _supabase
            .from('Messages')
            .select('msg_id')
            .eq('contract_id', contractId)
            .eq('message_type', 'contract')
            .inFilter('contract_status', ['approved', 'active'])
            .order('timestamp', ascending: false)
            .limit(1)
            .maybeSingle();

        if (approvedMessage != null) {
          await _supabase
              .from('Messages')
              .update({'signed_pdf_url': filePath})
              .eq('msg_id', approvedMessage['msg_id']);
        }

      } catch (dbError) {

        try {
          await _supabase.storage.from('contracts').remove([filePath]);
        } catch (cleanupError) {
          rethrow; 
        }
        throw Exception('Database update failed: $dbError');
      }

      await _auditService.logAuditEvent(
        action: 'SIGNED_CONTRACT_PDF_CREATED',
        details: 'Signed contract PDF created and uploaded',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
          'contractor_id': contractorId,
          'contractee_id': contractData['contractee_id'],
          'project_id': contractData['project_id'],
          'file_path': filePath,
        },
      );

      print('[ContractPdfSignatureService] Signed PDF ready at $filePath');
      return filePath;
    } catch (e) {
      print('[ContractPdfSignatureService] Failed to create signed contract PDF: $e');
      await _errorService.logError(
        errorMessage: 'Failed to create signed contract PDF: $e',
        module: 'Contract PDF Signature Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Create Signed Contract PDF',
          'contract_id': contractId,
        },
      );
      throw Exception('Failed to create signed contract PDF: $e');
    }
  }

  static Future<void> checkAndGenerateSignedPdf(String contractId) async {
    try {
      final contractData = await ContractService.getContractById(contractId);
      
      final contractorSigned = contractData['contractor_signature_url'] != null &&
          (contractData['contractor_signature_url'] as String).isNotEmpty;
      final contracteeSigned = contractData['contractee_signature_url'] != null &&
          (contractData['contractee_signature_url'] as String).isNotEmpty;

      final hasSignedPdf = contractData['signed_pdf_url'] != null && 
           (contractData['signed_pdf_url'] as String).isNotEmpty;

      await _auditService.logAuditEvent(
        action: 'CHECK_SIGNED_PDF_GENERATION',
        details: 'Checking if signed PDF should be generated - Contractor signed: $contractorSigned, Contractee signed: $contracteeSigned, Has signed PDF: $hasSignedPdf',
        category: 'Contract',
        metadata: {
          'contract_id': contractId,
          'contractor_signed': contractorSigned,
          'contractee_signed': contracteeSigned,
          'has_signed_pdf': hasSignedPdf,
          'contractor_signature_url': contractData['contractor_signature_url'],
          'contractee_signature_url': contractData['contractee_signature_url'],
        },
      );

      if (contractorSigned && 
          contracteeSigned && 
          !hasSignedPdf) {
        
        await _auditService.logAuditEvent(
          action: 'INITIATING_SIGNED_PDF_CREATION',
          details: 'Both parties have signed, creating signed PDF',
          category: 'Contract',
          metadata: {
            'contract_id': contractId,
          },
        );

        await createSignedContractPdf(contractId: contractId);
      } else {
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check and generate signed PDF: $e',
        module: 'Contract PDF Signature Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Check and Generate Signed PDF',
          'contract_id': contractId,
          'error': e.toString(),
        },
      );
      rethrow;
    }
  }
}
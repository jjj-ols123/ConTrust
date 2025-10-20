// ignore_for_file: file_names

import 'dart:typed_data';
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
        case 'cost plus contract':
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

      return await pdf.save();
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

      final fileName = 'signed_${contractId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$contractorId/$fileName';

      await _supabase.storage
          .from('contracts')
          .uploadBinary(filePath, pdfBytes, fileOptions: const FileOptions(upsert: true));

      try {
        final files = await _supabase.storage
            .from('contracts')
            .list(path: contractorId);

        final fileExists = files.any((file) => file.name == fileName);

        if (!fileExists) {
          throw Exception('File was not found in storage after upload (list check failed)');
        }
      } catch (listError) {
        try {
          await _supabase.storage
              .from('contracts')
              .download(filePath);
        } catch (downloadError) {
          throw Exception('Failed to verify file upload via both list and download: list=$listError, download=$downloadError');
        }
      }

      try {
        final testSignedUrl = await _supabase.storage
            .from('contracts')
            .createSignedUrl(filePath, 60);

        if (testSignedUrl.isEmpty) {
          throw Exception('Failed to create signed URL for uploaded file');
        }
      } catch (e) {
        throw Exception('Signed PDF uploaded but signed URL creation failed: ');
      }

      try {
        await _supabase
            .from('Contracts')
            .update({
              'signed_pdf_url': filePath,
            })
            .eq('contract_id', contractId);

        await _supabase
            .from('Messages')
            .update({'pdf_url': filePath})  
            .eq('contract_id', contractId)
            .inFilter('contract_status', ['approved', 'active']);  

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
          'file_path': filePath,
        },
      );

      return filePath;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to create signed contract PDF: ',
        module: 'Contract PDF Signature Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Create Signed Contract PDF',
          'contract_id': contractId,
        },
      );
      throw Exception('Failed to create signed contract PDF: ');
    }
  }

  static Future<void> checkAndGenerateSignedPdf(String contractId) async {
    try {
      final contractData = await ContractService.getContractById(contractId);
      
      final contractorSigned = contractData['contractor_signature_url'] != null &&
          (contractData['contractor_signature_url'] as String).isNotEmpty;
      final contracteeSigned = contractData['contractee_signature_url'] != null &&
          (contractData['contractee_signature_url'] as String).isNotEmpty;

      if (contractorSigned && 
          contracteeSigned && 
          (contractData['signed_pdf_url'] == null || 
           (contractData['signed_pdf_url'] as String).isEmpty)) {
        
        await createSignedContractPdf(contractId: contractId);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to check and generate signed PDF: ',
        module: 'Contract PDF Signature Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Check and Generate Signed PDF',
          'contract_id': contractId,
        },
      );
      rethrow;
    }
  }
}
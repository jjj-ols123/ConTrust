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
    print('🖨️ SIGNED PDF GENERATION: Starting PDF generation for contract ${contractData['contract_id']}');
    try {
      final contractTypeId = contractData['contract_type_id'] as String?;

      if (contractTypeId == null) {
        throw Exception('Contract type ID is missing');
      }

      print('🔍 SIGNED PDF GENERATION: Fetching contract type data');
      final contractTypeData = await _supabase
          .from('ContractTypes')
          .select('template_name')
          .eq('contract_type_id', contractTypeId)
          .single();

      final contractType = contractTypeData['template_name'] as String?;

      if (contractType == null) {
        throw Exception('Contract type not found for ID: $contractTypeId');
      }
      print('📄 SIGNED PDF GENERATION: Contract type identified - $contractType');
      
      List<pw.Widget> pdfWidgets;
      print('🏗️ SIGNED PDF GENERATION: Building PDF widgets for $contractType');
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
      print('✅ SIGNED PDF GENERATION: PDF widgets built successfully - ${pdfWidgets.length} widgets');

      print('📄 SIGNED PDF GENERATION: Creating PDF document');
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => pdfWidgets,
        ),
      );

      print('💾 SIGNED PDF GENERATION: Saving PDF to bytes');
      final pdfBytes = await pdf.save();
      print('✅ SIGNED PDF GENERATION: PDF saved successfully - ${pdfBytes.length} bytes');
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
    print('🔄 SIGNED PDF CREATION: Starting for contract $contractId');
    try {
      print('📋 SIGNED PDF CREATION: Fetching contract data');
      final contractData = await ContractService.getContractById(contractId);
      print('✅ SIGNED PDF CREATION: Contract data retrieved successfully');

      final contractorId = contractData['contractor_id'] as String?;
      if (contractorId == null) {
        throw Exception('Contractor ID not found in contract data');
      }
      print('👷 SIGNED PDF CREATION: Contractor ID found - $contractorId');

      final rawFieldValues = contractData['field_values'];
      final fieldValues = rawFieldValues is Map
          ? Map<String, String>.from(rawFieldValues.map((key, value) => MapEntry(key.toString(), value.toString())))
          : <String, String>{};
      print('📝 SIGNED PDF CREATION: Field values processed - ${fieldValues.length} fields');

      print('📥 SIGNED PDF CREATION: Downloading contractor signature');
      final contractorSignature = await downloadSignature(
        contractData['contractor_signature_url'],
      );
      print('✅ SIGNED PDF CREATION: Contractor signature downloaded - ${contractorSignature != null ? 'Success' : 'Not found'}');

      print('📥 SIGNED PDF CREATION: Downloading contractee signature');
      final contracteeSignature = await downloadSignature(
        contractData['contractee_signature_url'],
      );
      print('✅ SIGNED PDF CREATION: Contractee signature downloaded - ${contracteeSignature != null ? 'Success' : 'Not found'}');

      print('🎨 SIGNED PDF CREATION: Generating signed PDF with signatures');
      final pdfBytes = await generateSignedPdf(
        contractData: contractData,
        fieldValues: fieldValues,
        contractorSignature: contractorSignature,
        contracteeSignature: contracteeSignature,
      );
      print('✅ SIGNED PDF CREATION: Signed PDF generated successfully - ${pdfBytes.length} bytes');

      final fileName = 'signed_${contractId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$contractorId/$fileName';
      print('☁️ SIGNED PDF CREATION: Uploading PDF to storage - Path: $filePath');

      await _supabase.storage
          .from('contracts')
          .uploadBinary(filePath, pdfBytes, fileOptions: const FileOptions(upsert: true));
      print('✅ SIGNED PDF CREATION: PDF uploaded to storage successfully');

      print('🔍 SIGNED PDF CREATION: Verifying file upload');
      try {
        final files = await _supabase.storage
            .from('contracts')
            .list(path: contractorId);

        final fileExists = files.any((file) => file.name == fileName);

        if (!fileExists) {
          throw Exception('File was not found in storage after upload (list check failed)');
        }
        print('✅ SIGNED PDF CREATION: File verified in storage');
      } catch (listError) {
        print('⚠️ SIGNED PDF CREATION: List verification failed, trying download verification');
        try {
          await _supabase.storage
              .from('contracts')
              .download(filePath);
          print('✅ SIGNED PDF CREATION: File verified via download');
        } catch (downloadError) {
          throw Exception('Failed to verify file upload via both list and download: list=$listError, download=$downloadError');
        }
      }

      print('🔗 SIGNED PDF CREATION: Testing signed URL creation');
      try {
        final testSignedUrl = await _supabase.storage
            .from('contracts')
            .createSignedUrl(filePath, 60);

        if (testSignedUrl.isEmpty) {
          throw Exception('Failed to create signed URL for uploaded file');
        }
        print('✅ SIGNED PDF CREATION: Signed URL created successfully');
      } catch (e) {
        throw Exception('Signed PDF uploaded but signed URL creation failed: ');
      }

      print('💾 SIGNED PDF CREATION: Updating contract record with signed PDF URL');
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
          print('✅ SIGNED PDF CREATION: Updated approved contract message with signed PDF URL');
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
          'file_path': filePath,
        },
      );

      print('🎉 SIGNED PDF CREATION: COMPLETED SUCCESSFULLY - File: $filePath');
      return filePath;
    } catch (e) {
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
    print('🔍 SIGNED PDF CHECK: Checking if signed PDF should be generated for contract $contractId');
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

        print('🚀 SIGNED PDF CHECK: Both parties signed and no signed PDF exists - Starting creation process');
        await _auditService.logAuditEvent(
          action: 'INITIATING_SIGNED_PDF_CREATION',
          details: 'Both parties have signed, creating signed PDF',
          category: 'Contract',
          metadata: {
            'contract_id': contractId,
          },
        );

        await createSignedContractPdf(contractId: contractId);
        print('✅ SIGNED PDF CHECK: Signed PDF creation process completed');
      } else {
        print('ℹ️ SIGNED PDF CHECK: Signed PDF creation not needed - Status: Contractor: $contractorSigned, Contractee: $contracteeSigned, Has PDF: $hasSignedPdf');
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
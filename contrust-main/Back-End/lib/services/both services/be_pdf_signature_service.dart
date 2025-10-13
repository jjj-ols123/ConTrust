// ignore_for_file: file_names

import 'dart:typed_data';
import 'package:backend/contract_templates/TimeandMaterialsPDF.dart';
import 'package:backend/contract_templates/LumpSumPDF.dart';
import 'package:backend/contract_templates/CostPlusPDF.dart';
import 'package:backend/services/both services/be_contract_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractPdfSignatureService {
  static final _supabase = Supabase.instance.client;

  static Future<Uint8List> generateSignedPdf({
    required Map<String, dynamic> contractData,
    required Map<String, String> fieldValues,
    Uint8List? contractorSignature,
    Uint8List? contracteeSignature,
  }) async {
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
  }

  static Future<Uint8List?> downloadSignature(String? signaturePath) async {
    if (signaturePath == null || signaturePath.isEmpty) return null;
    
    try {
      if (signaturePath.startsWith('http')) {
        return null;
      }
      
      final response = await _supabase.storage
          .from('signatures')
          .download(signaturePath);
      
      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<String> createSignedContractPdf({
    required String contractId,
  }) async {
    try {
      final contractData = await ContractService.getContractById(contractId);

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
      final filePath = 'contracts/signed/$fileName';
      
      await _supabase.storage
          .from('contracts')
          .uploadBinary(filePath, pdfBytes);
      

      await _supabase
          .from('Contracts')
          .update({
            'signed_pdf_url': filePath,
          })
          .eq('contract_id', contractId);
      
      return filePath;
    } catch (e) {
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

      if (contractorSigned && 
          contracteeSigned && 
          (contractData['signed_pdf_url'] == null || 
           (contractData['signed_pdf_url'] as String).isEmpty)) {
        
        await createSignedContractPdf(contractId: contractId);
      }
    } catch (e) {
      rethrow;
    }
  }
}
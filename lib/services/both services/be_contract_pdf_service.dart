// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../contract_templates/TimeandMaterialsPDF.dart';
import '../../contract_templates/LumpSumPDF.dart';
import '../../contract_templates/CostPlusPDF.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

import 'dart:html' as html;

class ContractPdfService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final SuperAdminAuditService _auditService = SuperAdminAuditService();
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  static Future<Uint8List> generateContractPdf({
    required String contractType,
    required Map<String, String> fieldValues,
    required String title,
  }) async {
    try {
      final pdf = pw.Document();
      final normalizedType = contractType.toLowerCase();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            if (normalizedType.contains('time and materials')) {
              return TimeAndMaterialsPDF.buildTimeAndMaterialsPdf(fieldValues);
            } else if (normalizedType.contains('lump sum')) {
              return LumpSumPDF.buildLumpSumPdf(fieldValues);
            } else if (normalizedType.contains('cost-plus') || normalizedType.contains('cost plus')) {
              return CostPlusPDF.buildCostPlusPdf(fieldValues);
            } else {
              return [
                pw.Center(
                  child: pw.Text(
                    'CONSTRUCTION CONTRACT',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Generic contract template.'),
              ];
            }
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to generate contract PDF: $e',
        module: 'Contract PDF Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Generate Contract PDF',
          'contract_type': contractType,
          'title': title,
        },
      );
      rethrow;
    }
  }

  static Future<String> uploadContractPdfToStorage({
    required Uint8List pdfBytes,
    required String contractorId,
    required String projectId,
    required String contracteeId,
    String? contractId, 
  }) async {
    try {
      final uuid = const Uuid().v4();
    final fileName = '${projectId}_${contracteeId}_$uuid.pdf';
      final filePath = '$contractorId/$fileName'; 

      await _supabase.storage
          .from('contracts')
          .uploadBinary(filePath, pdfBytes, fileOptions: const FileOptions(upsert: false));

      await _auditService.logAuditEvent(
        userId: contractorId,
        action: 'CONTRACT_PDF_UPLOADED',
        details: 'Contract PDF uploaded to storage',
        category: 'Contract',
        metadata: {
          'contractor_id': contractorId,
          'project_id': projectId,
          'contractee_id': contracteeId,
          'file_path': filePath,
        },
      );

      return filePath;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to upload contract PDF: $e',
        module: 'Contract PDF Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Upload Contract PDF',
          'contractor_id': contractorId,
          'project_id': projectId,
        },
      );
      throw Exception('Failed to upload contract PDF: $e');
    }
  }

  static Future<Uint8List> downloadContractPdf(String pdfPath) async {
    try {
      final response = await _supabase.storage
          .from('contracts')
          .download(pdfPath);
      
      return response;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to download contract PDF: $e',
        module: 'Contract PDF Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download Contract PDF',
          'pdf_path': pdfPath,
        },
      );
      throw Exception('Failed to download contract PDF: $e');
    }
  }

  static Future<dynamic> saveToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      if (kIsWeb) {
        return downloadFileWeb(pdfBytes, fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        return file;
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to save contract PDF to device: $e',
        module: 'Contract PDF Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Save to Device',
          'file_name': fileName,
        },
      );
      rethrow;
    }
  }

  static void downloadFileWeb(Uint8List bytes, String fileName) {
    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        (html.AnchorElement(href: url)
          ..setAttribute('download', fileName)).click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      _errorService.logError(
        errorMessage: 'Failed to download file on web: $e',
        module: 'Contract PDF Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Download File Web',
          'file_name': fileName,
        },
      );
    }
  }
}
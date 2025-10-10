// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../contract_templates/TimeandMaterialsPDF.dart';
import '../../contract_templates/LumpSumPDF.dart';
import '../../contract_templates/CostPlusPDF.dart';

import 'dart:html' as html;

class ContractPdfService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Uint8List> generateContractPdf({
    required String contractType,
    required Map<String, String> fieldValues,
    required String title,
  }) async {
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
  }

  static Future<String> uploadContractPdf({
    required Uint8List pdfBytes,
    required String contractorId,
    required String projectId,
    required String contracteeId,
  }) async {
    try {
      final fileName = '${projectId}_$contracteeId.pdf';
      final filePath = '$contractorId/$fileName';

      await _supabase.storage
          .from('contracts')
          .uploadBinary(filePath, pdfBytes, fileOptions: const FileOptions(upsert: true));

      return filePath;
    } catch (e) {
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
      throw Exception('Failed to download contract PDF: $e');
    }
  }

  static Future<dynamic> saveToDevice(Uint8List pdfBytes, String fileName) async {
    if (kIsWeb) {
      return downloadFileWeb(pdfBytes, fileName);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file;
    }
  }

  static void downloadFileWeb(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      (html.AnchorElement(href: url)
        ..setAttribute('download', fileName)).click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
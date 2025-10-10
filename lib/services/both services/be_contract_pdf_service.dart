import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractPdfService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<String> _loadTemplate(String contractType) async {
    try {
      final templateName = contractType.replaceAll(' ', '');
      final template = await rootBundle.loadString('assets/contract_templates/$templateName.txt');
      return template;
    } catch (e) {
      // Fallback template
      return '''
CONSTRUCTION CONTRACT

This Construction Contract is entered into on [DATE] between:

CONTRACTOR: [Contractor Name]
CLIENT: [Client Name]
WELCOME: [Welcome Message]
PROJECT: [Project Description]
LOCATION: [Project Location]

TERMS AND CONDITIONS:

1. The contractor agrees to complete the work as specified.
2. Payment terms and conditions as agreed.
3. Timeline: [Start Date] to [Completion Date]

SIGNATURES:
Contractor: _________________
Client: _________________
''';
    }
  }

  static String _fillTemplate(String template, Map<String, String> fieldValues) {
    String filledTemplate = template;
    
    fieldValues.forEach((key, value) {
      filledTemplate = filledTemplate.replaceAll('[$key]', value.isNotEmpty ? value : '____________');
    });
    
    return filledTemplate;
  }

  static Future<Uint8List> generateContractPdf({
    required String contractType,
    required Map<String, String> fieldValues,
    required String title,
  }) async {
    final pdf = pw.Document();

    // Load template and fill with values
    final template = await _loadTemplate(contractType);
    final filledContent = _fillTemplate(template, fieldValues);

    // Split content into lines for better formatting
    final lines = filledContent.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          for (String line in lines) {
            final trimmedLine = line.trim();
            
            if (trimmedLine.isEmpty) {
              widgets.add(pw.SizedBox(height: 8));
            } else if (trimmedLine.contains('CONTRACT') && trimmedLine.length < 50) {
              // Title lines
              widgets.add(
                pw.Center(
                  child: pw.Text(
                    trimmedLine,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 16));
            } else if (trimmedLine.endsWith(':') && trimmedLine.length < 50) {
              // Section headers
              widgets.add(pw.SizedBox(height: 12));
              widgets.add(
                pw.Text(
                  trimmedLine,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 6));
            } else if (trimmedLine.startsWith('- ') || RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
              // List items and numbered items
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                  child: pw.Text(
                    trimmedLine,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              );
            } else if (trimmedLine.contains('₱')) {
              // Amount lines
              widgets.add(
                pw.Text(
                  trimmedLine,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 4));
            } else if (trimmedLine.contains('_________________')) {
              // Signature lines
              widgets.add(pw.SizedBox(height: 20));
              widgets.add(
                pw.Text(
                  trimmedLine,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              );
            } else {
              // Regular text
              widgets.add(
                pw.Text(
                  trimmedLine,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              );
              widgets.add(pw.SizedBox(height: 4));
            }
          }

          // Add footer
          widgets.add(pw.SizedBox(height: 40));
          widgets.add(
            pw.Center(
              child: pw.Text(
                'Generated on ${DateTime.now().toString().split(' ')[0]}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          );

          return widgets;
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
      // Create file path: {contractor_id}/{project_id}_{contractee_id}.pdf
      final fileName = '${projectId}_$contracteeId.pdf';
      final filePath = '$contractorId/$fileName';

      // Upload to Supabase storage
      await _supabase.storage
          .from('contracts')
          .uploadBinary(filePath, pdfBytes, fileOptions: const FileOptions(upsert: true));

      return filePath;
    } catch (e) {
      throw Exception('Failed to upload contract PDF: $e');
    }
  }

  static Future<String> getContractPdfUrl(String pdfPath) async {
    try {
      final signedUrl = await _supabase.storage
          .from('contracts')
          .createSignedUrl(pdfPath, 60 * 60 * 24); // 24 hours
      
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get contract PDF URL: $e');
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

  static Future<File> saveToDevice(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }
}
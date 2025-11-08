// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_datetime_helper.dart';

class ReceiptService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  /// Generate PDF receipt for a payment
  static Future<Uint8List> generateReceiptPdf({
    required String paymentId,
    required double amount,
    required String projectTitle,
    required String contractorName,
    required String contracteeName,
    required String contracteeEmail,
    required String paymentDate,
    required String paymentReference,
    String? contractType,
    String? paymentStructure,
    int? milestoneNumber,
    String? milestoneDescription,
  }) async {
    try {
      final pdf = pw.Document();
      final formattedDate = _formatDate(paymentDate);
      final formattedAmount = 'PHP${amount.toStringAsFixed(2)}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 30),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'E-RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'ConTrust Payment Receipt',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'PAID',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Payment Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildDetailRow('Payment Reference:', paymentReference),
                    _buildDetailRow('Payment Date:', formattedDate),
                    _buildDetailRow('Amount:', formattedAmount),
                    if (contractType != null)
                      _buildDetailRow('Contract Type:', _formatContractType(contractType)),
                    if (paymentStructure != null)
                      _buildDetailRow('Payment Type:', _formatPaymentStructure(paymentStructure)),
                    if (milestoneNumber != null)
                      _buildDetailRow('Milestone:', 'Milestone #$milestoneNumber'),
                    if (milestoneDescription != null)
                      _buildDetailRow('Description:', milestoneDescription),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Project Information
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Project Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildDetailRow('Project Title:', projectTitle),
                    _buildDetailRow('Contractor:', contractorName),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Payer Information
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payer Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildDetailRow('Name:', contracteeName),
                    if (contracteeEmail.isNotEmpty)
                      _buildDetailRow('Email:', contracteeEmail),
                  ],
                ),
              ),

              pw.SizedBox(height: 40),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey, width: 1),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your payment!',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'This is an electronic receipt. Please keep this for your records.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on ${_formatDate(DateTimeHelper.getLocalTimeISOString())}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to generate receipt PDF: $e',
        module: 'Receipt Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Generate Receipt PDF',
          'payment_id': paymentId,
        },
      );
      rethrow;
    }
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  static String _formatContractType(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'lump_sum':
        return 'Lump Sum Contract';
      case 'percentage_based':
      case 'milestone':
        return 'Milestone-Based Contract';
      case 'custom':
        return 'Custom Contract';
      case 'time_and_materials':
        return 'Time and Materials Contract';
      case 'cost_plus':
        return 'Cost Plus Contract';
      default:
        return contractType;
    }
  }

  static String _formatPaymentStructure(String paymentStructure) {
    switch (paymentStructure.toLowerCase()) {
      case 'single':
        return 'Single Payment';
      case 'milestone':
        return 'Milestone Payment';
      case 'down':
        return 'Down Payment';
      case 'final':
        return 'Final Payment';
      default:
        return paymentStructure;
    }
  }

  /// Upload receipt PDF to storage
  static Future<String> uploadReceiptToStorage({
    required Uint8List pdfBytes,
    required String projectId,
    required String contracteeId,
    required String paymentId,
  }) async {
    try {
      final uuid = const Uuid().v4();
      final fileName = 'receipt_${projectId}_${paymentId}_$uuid.pdf';
      final filePath = '$contracteeId/$fileName';

      await _supabase.storage
          .from('receipts')
          .uploadBinary(
            filePath,
            pdfBytes,
            fileOptions: const FileOptions(upsert: false),
          );

      return filePath;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to upload receipt PDF: $e',
        module: 'Receipt Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Upload Receipt PDF',
          'project_id': projectId,
          'payment_id': paymentId,
        },
      );
      rethrow;
    }
  }

  /// Get signed URL for receipt
  static Future<String?> getReceiptSignedUrl(String receiptPath, {int expirationSeconds = 86400}) async {
    try {
      final response = await _supabase.storage
          .from('receipts')
          .createSignedUrl(receiptPath, expirationSeconds);
      
      if (response.isEmpty) {
        try {
          final publicUrl = _supabase.storage.from('receipts').getPublicUrl(receiptPath);
          return publicUrl;
        } catch (publicError) {
          return null;
        }
      }
      
      return response;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to get signed receipt URL: $e',
        module: 'Receipt Service',
        severity: 'Low',
        extraInfo: {'receipt_path': receiptPath},
      );
      
      try {
        final publicUrl = _supabase.storage.from('receipts').getPublicUrl(receiptPath);
        return publicUrl;
      } catch (publicError) {
        return null;
      }
    }
  }
}


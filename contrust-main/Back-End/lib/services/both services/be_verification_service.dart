import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class TextractService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> processDocument({
    required Uint8List imageBytes,
    required String filename,
    String analysisType = 'text',
  }) async {
    try {
      // 1. Create document record
      final documentResponse = await _supabase
          .from('documents')
          .insert({
            'original_filename': filename,
            'file_size': imageBytes.length,
            'file_type': _getFileType(filename),
            'processing_status': 'pending',
          })
          .select()
          .single();

      final documentId = documentResponse['id'];

      // 2. Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // 3. Call edge function
      final response = await _supabase.functions.invoke(
        'textract-processor',
        body: {
          'documentId': documentId,
          'imageBase64': base64Image,
          'analysisType': analysisType,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData?['error'] ?? errorData?['message'] ?? 'Processing failed';
        throw Exception('Processing failed: $errorMessage');
      }

      final result = response.data;
      return result['extractedText'] ?? '';

    } catch (e) {
      throw Exception('Failed to process document: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserDocuments() async {
    final response = await _supabase
        .from('documents')
        .select('''
          *,
          textract_results (
            id,
            extracted_text,
            confidence_score,
            processing_time_ms,
            created_at
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getDocumentDetails(String documentId) async {
    final response = await _supabase
        .from('documents')
        .select('''
          *,
          textract_results (
            *,
            document_blocks (*),
            extracted_key_values (*),
            extracted_tables (*)
          )
        ''')
        .eq('id', documentId)
        .single();

    return response;
  }

  String _getFileType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

}

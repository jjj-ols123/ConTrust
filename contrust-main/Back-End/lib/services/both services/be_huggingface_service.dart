import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class HuggingFaceService {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  static const String _functionName = 'wall-color-filter';

  /// Process an image with a wall color using Hugging Face API via Edge Function
  /// 
  /// [imageBase64] - The image as base64 encoded string
  /// [colorHex] - The hex color code (e.g., '#FF0000') to apply to the wall
  /// 
  /// Returns the processed image as base64 string, or null if an error occurred
  Future<String?> processWallColor({
    required String imageBase64,
    required String colorHex,
  }) async {
    try {
      final payload = {
        'image': imageBase64,
        'color': colorHex,
      };

      final response = await _supabase.functions.invoke(
        _functionName,
        body: jsonEncode(payload),
      );

      if (response.status != 200) {
        final errorMsg = response.data != null && response.data is Map
            ? (response.data as Map)['error']?.toString() ?? 'Unknown error'
            : 'Edge Function returned status ${response.status}';
        
        await _errorService.logError(
          errorMessage: 'Edge Function error: $errorMsg',
          module: 'Hugging Face Service',
          severity: 'High',
          extraInfo: {
            'operation': 'Process Wall Color',
            'function': _functionName,
            'status': response.status.toString(),
            'response_data': response.data?.toString(),
          },
        );
        throw Exception(errorMsg);
      }

      if (response.data == null) {
        await _errorService.logError(
          errorMessage: 'Edge Function returned no data. Status: ${response.status}',
          module: 'Hugging Face Service',
          severity: 'High',
          extraInfo: {
            'operation': 'Process Wall Color',
            'function': _functionName,
            'status': response.status.toString(),
          },
        );
        throw Exception('No data received from Edge Function (Status: ${response.status})');
      }

      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('error')) {
          final errorDetails = data['details'] != null 
              ? '${data['error']}: ${data['details']}'
              : data['error'].toString();
          
          await _errorService.logError(
            errorMessage: 'Edge Function error: $errorDetails',
            module: 'Hugging Face Service',
            severity: 'High',
            extraInfo: {
              'operation': 'Process Wall Color',
              'error': errorDetails,
              'full_response': jsonEncode(data),
            },
          );
          throw Exception(errorDetails);
        }
        
        if (data.containsKey('image')) {
          final imageBase64 = data['image'] as String?;
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            return imageBase64;
          } else {
            throw Exception('Image data is empty in response');
          }
        } else {
          // Log what we actually received
          await _errorService.logError(
            errorMessage: 'Edge Function response missing image key. Keys: ${data.keys.join(", ")}',
            module: 'Hugging Face Service',
            severity: 'High',
            extraInfo: {
              'operation': 'Process Wall Color',
              'response_keys': data.keys.toList().toString(),
              'response_sample': jsonEncode(data).substring(0, 500),
            },
          );
          throw Exception('Response missing image key. Received: ${data.keys.join(", ")}');
        }
      }

      final directResponse = response.data.toString();
      if (directResponse.isNotEmpty && !directResponse.startsWith('{')) {
        return directResponse;
      }
      
      throw Exception('Unexpected response format: ${response.data.runtimeType}');
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to process wall color: $e',
        module: 'Hugging Face Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Process Wall Color',
          'function': _functionName,
        },
      );
      return null;
    }
  }

  /// Check if the Edge Function is available
  Future<bool> checkServiceStatus() async {
    try {
      final response = await _supabase.functions.invoke(
        _functionName,
        body: jsonEncode({'action': 'ping'}),
      );
      return response.data != null;
    } catch (e) {
      return false;
    }
  }
}


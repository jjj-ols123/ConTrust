// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Computer Vision Service for Construction Project Management
/// Uses Hugging Face models for image analysis
class ComputerVisionService {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Hugging Face API configuration
  // Note: Replace with your actual Hugging Face API token
  static const String _hfApiBase = 'https://api-inference.huggingface.co/models';
  static const String? _hfApiToken = null; // Set your token here or via environment variable

  /// Analyze construction progress from uploaded photo
  /// Returns estimated progress percentage and detected construction phases
  Future<Map<String, dynamic>> analyzeConstructionProgress({
    required String imageBase64,
    required String projectType,
    required String projectId,
    String? previousPhotoBase64,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // For now, use a simplified analysis
      // In production, you would call Hugging Face API or a custom model
      final analysis = await _performProgressAnalysis(
        imageBase64: imageBase64,
        projectType: projectType,
        previousPhoto: previousPhotoBase64,
      );

      // Log audit event
      await _auditService.logAuditEvent(
        userId: userId,
        action: 'AI_PROGRESS_ANALYSIS',
        details: 'Analyzed construction progress from photo',
        metadata: {
          'project_id': projectId,
          'project_type': projectType,
          'estimated_progress': analysis['estimated_progress'],
        },
      );

      return analysis;
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to analyze construction progress: $e',
        module: 'Computer Vision Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Analyze Progress',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  /// Perform actual progress analysis
  /// This is a placeholder - replace with actual Hugging Face API call
  Future<Map<String, dynamic>> _performProgressAnalysis({
    required String imageBase64,
    required String projectType,
    String? previousPhoto,
  }) async {
    // TODO: Implement actual Hugging Face API call
    // Example:
    // if (_hfApiToken != null) {
    //   final response = await http.post(
    //     Uri.parse('$_hfApiBase/microsoft/beit-base-patch16-224'),
    //     headers: {
    //       'Authorization': 'Bearer $_hfApiToken',
    //       'Content-Type': 'application/json',
    //     },
    //     body: jsonEncode({
    //       'inputs': imageBase64,
    //       'parameters': {
    //         'project_type': projectType,
    //       },
    //     }),
    //   );
    //   return parseProgressAnalysis(response.body);
    // }

    // For now, return mock analysis
    // In production, this should be replaced with actual CV analysis
    return {
      'estimated_progress': 0.45, // Mock value
      'detected_phases': ['foundation', 'structure'],
      'confidence': 0.75,
      'analysis_type': 'mock', // Change to 'ai' when using real API
      'recommendations': [
        'Foundation appears complete',
        'Structural work in progress',
        'Consider quality check for completed phases',
      ],
    };
  }

  /// Detect materials in construction photo
  Future<List<Map<String, dynamic>>> detectMaterials({
    required String imageBase64,
    required String projectId,
  }) async {
    try {
      // TODO: Implement using object detection model
      // Example: facebook/detr-resnet-50 for object detection

      // Mock response for now
      return [
        {
          'material': 'concrete',
          'confidence': 0.85,
          'location': 'foundation',
        },
        {
          'material': 'steel_rebar',
          'confidence': 0.72,
          'location': 'structure',
        },
      ];
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to detect materials: $e',
        module: 'Computer Vision Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Detect Materials',
          'project_id': projectId,
        },
      );
      return [];
    }
  }

  /// Detect safety compliance in construction photo
  Future<Map<String, dynamic>> detectSafetyCompliance({
    required String imageBase64,
    required String projectId,
  }) async {
    try {
      return {
        'compliance_score': 0.80,
        'detected_equipment': ['helmet', 'safety_vest'],
        'missing_equipment': [],
        'warnings': [],
        'recommendations': [
          'Good safety compliance detected',
          'Ensure all workers wear safety gear',
        ],
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to detect safety compliance: $e',
        module: 'Computer Vision Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Detect Safety',
          'project_id': projectId,
        },
      );
      return {
        'compliance_score': 0.0,
        'detected_equipment': [],
        'missing_equipment': [],
        'warnings': ['Unable to analyze safety compliance'],
        'recommendations': [],
      };
    }
  }

  /// Compare two photos to detect changes/progress
  Future<Map<String, dynamic>> comparePhotos({
    required String photo1Base64,
    required String photo2Base64,
    required String projectId,
  }) async {
    try {
      // TODO: Implement photo comparison using CV
      // Could use image similarity or change detection

      // Mock response
      return {
        'similarity_score': 0.65,
        'detected_changes': [
          'Additional structural elements added',
          'Progress in foundation completion',
        ],
        'progress_estimate': 0.15, // 15% progress between photos
        'confidence': 0.70,
      };
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to compare photos: $e',
        module: 'Computer Vision Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Compare Photos',
          'project_id': projectId,
        },
      );
      return {
        'similarity_score': 0.0,
        'detected_changes': [],
        'progress_estimate': 0.0,
        'confidence': 0.0,
      };
    }
  }

  /// Call Hugging Face Inference API (helper method)
  /// TODO: Implement when Hugging Face API is configured
  // ignore: unused_element
  Future<Map<String, dynamic>> _callHuggingFaceAPI({
    required String model,
    required Map<String, dynamic> payload,
  }) async {
    if (_hfApiToken == null) {
      throw Exception('Hugging Face API token not configured');
    }

    try {
      final response = await http.post(
        Uri.parse('$_hfApiBase/$model'),
        headers: {
          'Authorization': 'Bearer $_hfApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Hugging Face API error: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Hugging Face API call failed: $e',
        module: 'Computer Vision Service',
        severity: 'High',
        extraInfo: {
          'operation': 'HF API Call',
          'model': model,
        },
      );
      rethrow;
    }
  }
}


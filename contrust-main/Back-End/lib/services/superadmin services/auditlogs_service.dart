// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminAuditService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminErrorService errorService = SuperAdminErrorService();

  Future<List<Map<String, dynamic>>> getAllAuditLogs() async {
    try {
      final response = await _supabase
          .from('AuditLogs')
          .select('id, users_id, action, details, category, timestamp')
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch all audit logs: ',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch All Audit Logs',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch audit logs: ');
    }
  }

  Future<List<Map<String, dynamic>>> getAuditLogsByAction(String action) async {
    try {
      final response = await _supabase
          .from('AuditLogs')
          .select('id, users_id, action, details, category, timestamp')
          .eq('action', action)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch audit logs by action: ',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Audit Logs by Action',
          'action': action,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch audit logs by action: ');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentAuditLogs({int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('AuditLogs')
          .select('id, users_id, action, details, category, timestamp')
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch recent audit logs: $e',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Recent Audit Logs',
          'limit': limit,
          'offset': offset,
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch recent audit logs: $e');
    }
  }

  Future<Map<String, dynamic>> getAuditStatistics() async {
    try {
      final recentLogs = await _supabase
          .from('AuditLogs')
          .select('id')
          .order('timestamp', ascending: false)
          .limit(1000); 
      
      final totalLogs = recentLogs.length < 1000 
          ? recentLogs.length 
          : recentLogs.length; 

      final categoryResponse = await _supabase
          .from('AuditLogs')
          .select('category')
          .order('timestamp', ascending: false)
          .limit(5000); 
      
      final categoryCounts = <String, int>{};
      for (var log in categoryResponse) {
        final category = log['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final actionResponse = await _supabase
          .from('AuditLogs')
          .select('action')
          .order('timestamp', ascending: false)
          .limit(5000);

      final actionCounts = <String, int>{};
      for (var log in actionResponse) {
        final action = log['action']?.toString();
        if (action != null && action.isNotEmpty) {
          actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        }
      }

      return {
        'total_logs': totalLogs,
        'category_counts': categoryCounts,
        'action_counts': actionCounts,
      };
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to get audit statistics: $e',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Get Audit Statistics',
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to get audit statistics: $e');
    }
  }

  Future<void> logAuditEvent({
  String? userId,
  required String action,
  String? details,
  String? category,
  Map<String, dynamic>? metadata,
}) async {
  try {
    String? detailsJson;
    if (metadata != null) {
      final safeMetadata = metadata.map((key, value) {
        if (value is DateTime) return MapEntry(key, value.toIso8601String());
        if (value is! String && value is! num && value is! bool && value != null) {
          return MapEntry(key, value.toString());
        }
        return MapEntry(key, value);
      });
      detailsJson = jsonEncode(safeMetadata);
    } else {
      detailsJson = details;
    }

    await _supabase.from('AuditLogs').insert({
      'users_id': userId,
      'action': action,
      'details': detailsJson,
      'category': category ?? _deriveCategoryFromAction(action),
      'timestamp': DateTimeHelper.getLocalTimeISOString(),
    });
  } catch (e) {
    SuperAdminErrorService().logError(
      errorMessage: 'Failed to log audit event: $e',
      module: 'Audit Logs Service',
      severity: 'Medium',
      extraInfo: {
        'operation': 'Log Audit Event',
        'action': action,
        'timestamp': DateTimeHelper.getLocalTimeISOString(),
      },
    );
  }
}

  String _deriveCategoryFromAction(String action) {
    switch (action.toLowerCase()) {
      case 'user_registration':
      case 'user_login':
      case 'user_login_failed':
        return 'user';
      case 'admin_login':
        return 'admin';
      default:
        return 'system';
    }
  }
}

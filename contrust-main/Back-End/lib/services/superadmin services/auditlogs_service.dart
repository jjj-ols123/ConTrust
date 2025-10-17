// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminAuditService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminErrorService errorService = SuperAdminErrorService();

  Future<List<Map<String, dynamic>>> getAllAuditLogs() async {
    try {
      final response = await _supabase
          .from('AuditLogs')
          .select('*')
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch all audit logs: $e',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch All Audit Logs',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAuditLogsByAction(String action) async {
    try {
      final response = await _supabase
          .from('AuditLogs')
          .select('*')
          .eq('action', action)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch audit logs by action: $e',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Audit Logs by Action',
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch audit logs by action: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentAuditLogs({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('AuditLogs')
          .select('*')
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch recent audit logs: $e',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Recent Audit Logs',
          'limit': limit,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch recent audit logs: $e');
    }
  }

  Future<Map<String, dynamic>> getAuditStatistics() async {
    try {
      final totalLogs = await _supabase.from('AuditLogs').select('id').then((res) => res.length);

      final categories = await _supabase
          .from('AuditLogs')
          .select('category')
          .then((res) => res.map((log) => log['category']).toList());

      final categoryCounts = <String, int>{};
      for (var category in categories.where((c) => c != null)) {
        categoryCounts[category!] = (categoryCounts[category] ?? 0) + 1;
      }

      final actions = await _supabase
          .from('AuditLogs')
          .select('action')
          .then((res) => res.map((log) => log['action']).toList());

      final actionCounts = <String, int>{};
      for (var action in actions.where((a) => a != null)) {
        actionCounts[action!] = (actionCounts[action] ?? 0) + 1;
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
          'timestamp': DateTime.now().toIso8601String(),
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
      final detailsJson = metadata != null ? jsonEncode(metadata) : details;

      await _supabase.from('AuditLogs').insert({
        'users_id': userId,
        'action': action,
        'details': detailsJson,
        'category': category ?? _deriveCategoryFromAction(action),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to log audit event: $e',
        module: 'Audit Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Log Audit Event',
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
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

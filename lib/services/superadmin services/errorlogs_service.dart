// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminErrorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllErrorLogs() async {
    try {
      final response = await _supabase
          .from('ErrorLogs')
          .select('error_id, users_id, error_message, stack_trace, module, severity, timestamp, resolved, extra_info')
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch all error logs:',
        module: 'Error Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch All Error Logs',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch error logs: ');
    }
  }

  Future<List<Map<String, dynamic>>> getErrorLogsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('ErrorLogs')
          .select('error_id, users_id, error_message, stack_trace, module, severity, timestamp, resolved, extra_info')
          .eq('users_id', userId)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch error logs by user: ',
        module: 'Error Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Error Logs by User',
          'users_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch error logs by user: ');
    }
  }

  Future<List<Map<String, dynamic>>> getErrorLogsBySeverity(String severity) async {
    try {
      final response = await _supabase
          .from('ErrorLogs')
          .select('error_id, users_id, error_message, stack_trace, module, severity, timestamp, resolved, extra_info')
          .eq('severity', severity)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch error logs by severity: ',
        module: 'Error Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Error Logs by Severity',
          'severity': severity,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch error logs by severity: ');
    }
  }

  Future<List<Map<String, dynamic>>> getErrorLogsByModule(String module) async {
    try {
      final response = await _supabase
          .from('ErrorLogs')
          .select('error_id, users_id, error_message, stack_trace, module, severity, timestamp, resolved, extra_info')
          .eq('module', module)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch error logs by module:',
        module: 'Error Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Error Logs by Module',
          'module': module,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch error logs by module: ');
    }
  }

  Future<List<Map<String, dynamic>>> getUnresolvedErrorLogs() async {
    try {
      final response = await _supabase
          .from('ErrorLogs')
          .select('error_id, users_id, error_message, stack_trace, module, severity, timestamp, resolved, extra_info')
          .eq('resolved', false)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch unresolved error logs:',
        module: 'Error Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Unresolved Error Logs',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch unresolved error logs: ');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentErrorLogs({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('ErrorLogs')
          .select('error_id, users_id, error_message, stack_trace, module, severity, timestamp, resolved, extra_info')
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch recent error logs:',
        module: 'Error Logs Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Recent Error Logs',
          'limit': limit,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch recent error logs: ');
    }
  }

  Future<Map<String, dynamic>> getErrorStatistics() async {
    try {
      final totalLogs = await _supabase.from('ErrorLogs').select('error_id').then((res) => res.length);

      final severities = await _supabase
          .from('ErrorLogs')
          .select('severity')
          .then((res) => res.map((log) => log['severity']).toList());

      final severityCounts = <String, int>{};
      for (var severity in severities.where((s) => s != null)) {
        severityCounts[severity!] = (severityCounts[severity] ?? 0) + 1;
      }

      final modules = await _supabase
          .from('ErrorLogs')
          .select('module')
          .then((res) => res.map((log) => log['module']).toList());

      final moduleCounts = <String, int>{};
      for (var module in modules.where((m) => m != null)) {
        moduleCounts[module!] = (moduleCounts[module] ?? 0) + 1;
      }

      final unresolvedCount = await _supabase
          .from('ErrorLogs')
          .select('error_id')
          .eq('resolved', false)
          .then((res) => res.length);

      return {
        'total_logs': totalLogs,
        'severity_counts': severityCounts,
        'module_counts': moduleCounts,
        'unresolved_count': unresolvedCount,
      };
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch error statistics:',
        module: 'Error Logs Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Fetch Error Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to get error statistics: ');
    }
  }

 Future<void> logError({
  String? userId,
  required String errorMessage,
  String? stackTrace,
  String? module,
  String? severity = 'medium',
  Map<String, dynamic>? extraInfo,
}) async {
  try {
    Map<String, dynamic>? safeExtraInfo;
    if (extraInfo != null) {
      safeExtraInfo = extraInfo.map((key, value) {
        if (value is DateTime) {
          return MapEntry(key, value.toIso8601String());
        }
        if (value is! String && value is! num && value is! bool && value != null) {
          return MapEntry(key, value.toString());
        }
        return MapEntry(key, value);
      });
    }

    await _supabase.from('ErrorLogs').insert({
      'users_id': userId,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'module': module,
      'severity': severity,
      'timestamp': DateTime.now().toIso8601String(),
      'resolved': false,
      'extra_info': safeExtraInfo != null ? jsonEncode(safeExtraInfo) : null,
    });
  } catch (e) {
    return;
  }
}

  Future<void> markErrorResolved(String errorId) async {
    try {
      await _supabase
          .from('ErrorLogs')
          .update({'resolved': true})
          .eq('error_id', errorId);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to mark error as resolved: ',
        module: 'Error Logs Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Mark Error as Resolved',
          'error_id': errorId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to mark error as resolved: ');
    }
  }

  Future<void> markErrorUnresolved(String errorId) async {
    try {
      await _supabase
          .from('ErrorLogs')
          .update({'resolved': false})
          .eq('error_id', errorId);
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to mark error as unresolved: ',
        module: 'Error Logs Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Mark Error as Unresolved',
          'error_id': errorId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to mark error as unresolved: ');
    }
  }
}

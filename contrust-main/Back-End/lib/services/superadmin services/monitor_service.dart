 import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class SystemMonitorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<Map<String, dynamic>> getSystemHealth() async {
    final checks = await Future.wait([
      _checkDatabaseHealth(),
      _checkStorageHealth(),
    ]);

    final overallStatus = checks.any((check) => check['status'] == 'error')
        ? 'error'
        : checks.any((check) => check['status'] == 'warning')
            ? 'warning'
            : 'healthy';
            
    return {
      'overall_status': overallStatus,
      'checks': checks,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _checkDatabaseHealth() async {
    final startTime = DateTime.now();
    try {
      await _supabase.from('Users').select('users_id').limit(1);
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final status = responseTime < 100 ? 'healthy' : (responseTime < 500 ? 'warning' : 'error');
      
      return {
        'component': 'database',
        'status': status,
        'response_time_ms': responseTime,
        'metrics': {
          'query_success': true,
          'response_time': responseTime,
        },
      };
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'component': 'database',
        'status': 'error',
        'response_time_ms': responseTime,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _checkStorageHealth() async {
    final startTime = DateTime.now();
    try {
      await _supabase.storage.listBuckets();
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    
      return {
        'component': 'file_storage',
        'status': responseTime < 200 ? 'healthy' : 'warning',
        'response_time_ms': responseTime,
        'metrics': {'files_accessible': true},
      };
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'component': 'file_storage',
        'status': 'error',
        'response_time_ms': responseTime,
        'error': e.toString(),
      };
    }
  }
        
  Future<List<Map<String, dynamic>>> getSystemAlerts() async {
    try {
      final errorLogs = await _supabase
          .from('ErrorLogs')
          .select('error_id, error_message, severity, module, timestamp')
          .eq('resolved', false)
          .order('timestamp', ascending: false)
          .limit(5);

      return errorLogs
          .map((log) => {
                'error_id': log['error_id'],
                'message': log['error_message'],
                'severity': (log['severity'] as String).toLowerCase(),
                'module': log['module'],
                'timestamp': log['timestamp'],
                'type': 'error',
              })
          .toList();
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch system alerts: $e',
        module: 'System Monitor',
        severity: 'Medium',
        extraInfo: {'operation': 'Get System Alerts'},
      );
      throw Exception('Failed to fetch system alerts: $e');
    }
  }
}



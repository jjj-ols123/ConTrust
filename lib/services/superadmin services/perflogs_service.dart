import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class SuperAdminPerfLogsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static DateTime? _appStartTime;

  Future<List<Map<String, dynamic>>> getAllPerfLogs() async {
    try {
      final response = await _supabase
          .from('PerfLogs')
          .select('metric_name, metric_value, unit, recorded_at, source')
          .order('recorded_at', ascending: false)
          .limit(100); 

      return response.map((log) => {
        'metric_name': log['metric_name'],
        'metric_value': log['metric_value'],
        'unit': log['unit'],
        'recorded_at': log['recorded_at'],
        'source': log['source'],
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch performance logs: $e');
    }
  }

  Future<void> logPerformanceMetric(String metricName, double value, String unit, String source) async {
    try {
      await _supabase.from('PerfLogs').insert({
        'metric_name': metricName,
        'metric_value': value,
        'unit': unit,
        'source': source,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to log performance metric: ',
        module: 'Super Admin Perf Logs',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Log Performance Metric',
          'metric_name': metricName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to log performance metric: ');
    }
  }

  Future<Map<String, dynamic>> _executeWithMonitoring(
    String operationName, 
    Future<dynamic> Function() operation,
  ) async {
    final startTime = DateTime.now();
    try {
      final result = await operation();
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
 
      await logPerformanceMetric(
        '${operationName}_time',
        responseTime.toDouble(),
        'ms',
        'api_service',
      );
      
      return result;
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      await logPerformanceMetric(
        '${operationName}_error_time',
        responseTime.toDouble(),
        'ms',
        'api_service',
      );

      await logPerformanceMetric(
        'error_rate',
        1.0,
        'count',
        'api_service',
      );
      
      rethrow;
    }
  }

  Future<Future<Map<String, dynamic>>> getUsers() async {
    return _executeWithMonitoring('get_users', () async {
      return await _supabase
          .from('Users')
          .select()
          .then((response) => response);
    });
  }

  Future<Future<Map<String, dynamic>>> getProjects() async {
    return _executeWithMonitoring('get_projects', () async {
      return await _supabase
          .from('Projects')
          .select()
          .then((response) => response);
    });
  }

  Future<List<Map<String, dynamic>>> executeQueryWithMonitoring(
    String queryName, 
    Future<List<Map<String, dynamic>>> Function() query,
  ) async {
    final startTime = DateTime.now();
    try {
      final result = await query();
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      await logPerformanceMetric(
        '${queryName}_execution_time',
        executionTime.toDouble(),
        'ms',
        'database',
      );

      await logPerformanceMetric(
        '${queryName}_result_size',
        result.length.toDouble(),
        'records',
        'database',
      );
      
      return result;
    } catch (e) {
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;
      
      await logPerformanceMetric(
        '${queryName}_error_time',
        executionTime.toDouble(),
        'ms',
        'database',
      );
      
      rethrow;
    }
  }

  Future<T> trackUserAction<T>(
    String actionName,
    Future<T> Function() action,
  ) async {
    final startTime = DateTime.now();
    try {
      final result = await action();
      final actionTime = DateTime.now().difference(startTime).inMilliseconds;

      await logPerformanceMetric(
        'user_action_${actionName}_time',
        actionTime.toDouble(),
        'ms',
        'user_interface',
      );
      
      return result;
    } catch (e) {
      final actionTime = DateTime.now().difference(startTime).inMilliseconds;

      await logPerformanceMetric(
        'user_action_${actionName}_error',
        actionTime.toDouble(),
        'ms',
        'user_interface',
      );
      
      rethrow;
    }
  }

  static void recordAppStart() {
    _appStartTime = DateTime.now();
  }

  Future<void> recordAppReady() async {
    if (_appStartTime != null) {
      final startupTime = DateTime.now().difference(_appStartTime!).inMilliseconds;
      
      await logPerformanceMetric(
        'app_startup_time',
        startupTime.toDouble(),
        'ms',
        'application',
      );
    }
  }

  Future<void> recordScreenLoad(String screenName) async {
    final startTime = DateTime.now();
    
    final loadTime = DateTime.now().difference(startTime).inMilliseconds;
    
    await logPerformanceMetric(
      'screen_${screenName}_load_time',
      loadTime.toDouble(),
      'ms',
      'user_interface',
    );
  }
  
}
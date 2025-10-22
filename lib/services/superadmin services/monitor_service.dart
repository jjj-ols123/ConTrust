 import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/perflogs_service.dart';

class SystemMonitorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminPerfLogsService _perfLogsService = SuperAdminPerfLogsService();
  
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

    await _perfLogsService.logPerformanceMetric(
      'system_health_score',
      overallStatus == 'healthy'
          ? 100
          : overallStatus == 'warning'
              ? 50
              : 0,
      'points',
      'system_health',
    );
    
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
      
      try {
        await _perfLogsService.logPerformanceMetric(
          'database_health_check_time',
          responseTime.toDouble(),
          'ms',
          'system_health',
        );
      } catch (e) {
        print('Warning: Failed to log database health metric: $e');
      }
      
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
        
      try {
        await _perfLogsService.logPerformanceMetric(
          'database_health_check_error',
          responseTime.toDouble(),
          'ms',
          'system_health',
        );
      } catch (logError) {
        print('Warning: Failed to log database error metric: $logError');
      }
      
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
      
      try {
        await _perfLogsService.logPerformanceMetric(
          'storage_health_check_time',
          responseTime.toDouble(),
          'ms',
          'system_health',
        );
      } catch (e) {
        print('Warning: Failed to log storage health metric: $e');
      }
      
      return {
        'component': 'file_storage',
        'status': responseTime < 200 ? 'healthy' : 'warning',
        'response_time_ms': responseTime,
        'metrics': {'files_accessible': true},
      };
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
        
      try {
        await _perfLogsService.logPerformanceMetric(
          'storage_health_check_error',
          responseTime.toDouble(),
          'ms',
          'system_health',
        );
      } catch (logError) {
        print('Warning: Failed to log storage error metric: $logError');
      }
      
      return {
        'component': 'file_storage',
        'status': 'error',
        'response_time_ms': responseTime,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final recentLogs = await _supabase
          .from('PerfLogs')
          .select('metric_name, metric_value, unit, recorded_at, source')
          .order('recorded_at', ascending: false)
          .limit(100);

      final apiResponseTimes = recentLogs
          .where((log) =>
              log['metric_name'].toString().contains('_time') &&
              log['source'] == 'api_service')
          .map((log) => log['metric_value'] as num)
          .toList();

      final dbQueryTimes = recentLogs
          .where((log) => log['source'] == 'database')
          .map((log) => log['metric_value'] as num)
          .toList();

      final errorRates = recentLogs
          .where((log) => log['metric_name'].toString().contains('error_rate'))
          .map((log) => log['metric_value'] as num)
          .toList();

      final metrics = [
        {
          'metric': 'api_response_times',
          'status': _calculateMetricStatus(apiResponseTimes, 100, 500),
          'average_ms': _calculateAverage(apiResponseTimes),
          'p95_ms': _calculatePercentile(apiResponseTimes, 95),
          'requests_count': apiResponseTimes.length,
        },
        {
          'metric': 'database_query_times',
          'status': _calculateMetricStatus(dbQueryTimes, 50, 200),
          'average_ms': _calculateAverage(dbQueryTimes),
          'p95_ms': _calculatePercentile(dbQueryTimes, 95),
        },
        {
          'metric': 'error_rates',
          'status': _calculateErrorRateStatus(errorRates),
          'error_rate_percent': _calculateAverage(errorRates),
          'total_errors': errorRates.length,
        },
      ];

      return {
        'metrics': metrics,
        'total_logs': recentLogs.length,
        'time_range': 'last_24_hours',
      };
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to get performance metrics: $e',
        module: 'System Monitor',
        severity: 'Medium',
        extraInfo: {'operation': 'Get Performance Metrics'},
      );
      throw Exception('Failed to fetch backend performance metrics: $e');
    }
  }

  String _calculateMetricStatus(List<num> values, num warningThreshold, num errorThreshold) {
    if (values.isEmpty) return 'good';

    final average = _calculateAverage(values);
    if (average >= errorThreshold) return 'error';
    if (average >= warningThreshold) return 'warning';
    return 'good';
  }

  double _calculateAverage(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _calculateErrorRateStatus(List<num> errorRates) {
    if (errorRates.isEmpty) return 'good';
    final averageErrorRate = _calculateAverage(errorRates);
    if (averageErrorRate >= 5.0) return 'error';
    if (averageErrorRate >= 1.0) return 'warning';
    return 'good';
  }

  double _calculatePercentile(List<num> values, int percentile) {
    if (values.isEmpty) return 0.0;

    final sorted = List<num>.from(values)..sort();

    if (sorted.length == 1) return sorted[0].toDouble();

    final index = (percentile / 100 * (sorted.length - 1)).round();

    final safeIndex = index.clamp(0, sorted.length - 1);
    return sorted[safeIndex].toDouble();
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



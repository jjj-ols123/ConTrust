import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:backend/services/superadmin%20services/perflogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminServiceBackend {
  static final SuperAdminPerfLogsService _perfLogsService =
      SuperAdminPerfLogsService();
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final userStats =
          await _supabase.from('Users').select('role').then((response) {
        final data = response as List<dynamic>;
        final totalUsers = data.length;
        final contractors =
            data.where((user) => user['role'] == 'contractor').length;
        final contractees =
            data.where((user) => user['role'] == 'contractee').length;

        return {
          'total': totalUsers,
          'contractors': contractors,
          'contractees': contractees,
        };
      });

      final projectStats =
          await _supabase.from('Projects').select('status').then((response) {
        final data = response as List<dynamic>;
        final totalProjects = data.length;
        final activeProjects =
            data.where((project) => project['status'] == 'active').length;
        final completedProjects =
            data.where((project) => project['status'] == 'completed').length;

        return {
          'total': totalProjects,
          'active': activeProjects,
          'completed': completedProjects,
        };
      });

      return {
        'users': userStats,
        'projects': projectStats,
      };
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch system statistics: ',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch System Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch system statistics: ');
    }
  }

  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final recentUsers = await _supabase
          .from('Users')
          .select('users_id, email, created_at, role')
          .order('created_at', ascending: false)
          .limit(5)
          .then((response) => response);

      final recentProjects = await _supabase
          .from('Projects')
          .select('project_id, title, status, created_at')
          .order('created_at', ascending: false)
          .limit(5)
          .then((response) => response);

      final recentAuditLogs = await _supabase
          .from('AuditLogs')
          .select('id, action, category, users_id, timestamp, details')
          .order('timestamp', ascending: false)
          .limit(10)
          .then((response) => response);

      return {
        'recent_users': recentUsers,
        'recent_projects': recentProjects,
        'recent_audit_logs': recentAuditLogs,
      };
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch dashboard data: ',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Dashboard Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch dashboard data: ');
    }
  }

  static Future<List<Map<String, dynamic>>> getSystemAlerts() async {
    try {
      final errorLogs = await _supabase
          .from('ErrorLogs')
          .select('error_id, error_message, severity, module, timestamp')
          .eq('resolved', false)
          .order('timestamp', ascending: false)
          .limit(5)
          .then((response) => response);

      return errorLogs
          .map((log) => {
                'error_id': log['error_id'],
                'error_message': log['error_message'],
                'severity': log['severity'],
                'module': log['module'],
                'timestamp': log['timestamp'],
              })
          .toList();
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch system alerts: ',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch System Alerts',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch system alerts: ');
    }
  }

  static Future<Map<String, dynamic>> getSystemHealthStatus() async {
    final checks = <Map<String, dynamic>>[];

    final dbStart = DateTime.now();
    try {
      final dbResponseTime = DateTime.now().difference(dbStart).inMilliseconds;

      await _perfLogsService.logPerformanceMetric(
        'database_health_check_time',
        dbResponseTime.toDouble(),
        'ms',
        'system_health',
      );

      final dbStatus = dbResponseTime < 100
          ? 'healthy'
          : dbResponseTime < 500
              ? 'warning'
              : 'error';

      checks.add({
        'component': 'database',
        'status': dbStatus,
        'response_time_ms': dbResponseTime,
        'metrics': {
          'query_success': true,
          'response_time': dbResponseTime,
        },
      });
    } catch (e) {
      final dbResponseTime = DateTime.now().difference(dbStart).inMilliseconds;

      await _perfLogsService.logPerformanceMetric(
        'database_health_check_error',
        dbResponseTime.toDouble(),
        'ms',
        'system_health',
      );

      checks.add({
        'component': 'database',
        'status': 'error',
        'response_time_ms': dbResponseTime,
        'error': e.toString(),
      });
    }

    checks.add(await _checkStorageHealth());

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

  static Future<Map<String, dynamic>> _checkStorageHealth() async {
    final startTime = DateTime.now();
    try {
      await _supabase.storage.from('your-bucket').list();
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      await _perfLogsService.logPerformanceMetric(
        'storage_health_check_time',
        responseTime.toDouble(),
        'ms',
        'system_health',
      );

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

  static Future<Map<String, dynamic>> getBackendPerformanceMetrics() async {
    try {
      final recentPerfLogs = await _supabase
          .from('PerfLogs')
          .select('metric_name, metric_value, unit, recorded_at, source')
          .order('recorded_at', ascending: false)
          .limit(100)
          .then((response) => response);

      final apiResponseTimes = recentPerfLogs
          .where((log) =>
              log['metric_name'].toString().contains('_time') &&
              log['source'] == 'api_service')
          .map((log) => log['metric_value'] as num)
          .toList();

      final errorRates = recentPerfLogs
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
          'status': _calculateMetricStatus(
              recentPerfLogs
                  .where((log) => log['source'] == 'database')
                  .map((log) => log['metric_value'] as num)
                  .toList(),
              50,
              200),
          'average_ms': _calculateAverage(recentPerfLogs
              .where((log) => log['source'] == 'database')
              .map((log) => log['metric_value'] as num)
              .toList()),
          'p95_ms': _calculatePercentile(
              recentPerfLogs
                  .where((log) => log['source'] == 'database')
                  .map((log) => log['metric_value'] as num)
                  .toList(),
              95),
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
        'total_logs': recentPerfLogs.length,
        'time_range': 'last_24_hours',
      };
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch backend performance metrics: $e',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Backend Performance Metrics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch backend performance metrics: $e');
    }
  }

  static String _calculateMetricStatus(
      List<num> values, num warningThreshold, num errorThreshold) {
    if (values.isEmpty) return 'unknown';

    final average = _calculateAverage(values);
    if (average >= errorThreshold) return 'error';
    if (average >= warningThreshold) return 'warning';
    return 'good';
  }

  static double _calculateAverage(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static String _calculateErrorRateStatus(List<num> errorRates) {
    if (errorRates.isEmpty) return 'good';
    final averageErrorRate = _calculateAverage(errorRates);
    if (averageErrorRate >= 5.0) return 'error';
    if (averageErrorRate >= 1.0) return 'warning';
    return 'good';
  }

  static double _calculatePercentile(List<num> values, int percentile) {
    if (values.isEmpty) return 0.0;

    final sorted = List<num>.from(values)..sort();

    if (sorted.length == 1) return sorted[0].toDouble();

    final index = (percentile / 100 * (sorted.length - 1)).round();

    final safeIndex = index.clamp(0, sorted.length - 1);
    return sorted[safeIndex].toDouble();
  }
}

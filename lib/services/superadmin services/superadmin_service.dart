import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminServiceBackend {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final userStats = await _supabase
          .from('Users')
          .select('role')
          .then((response) {
            final data = response as List<dynamic>;
            final totalUsers = data.length;
            final contractors = data.where((user) => user['role'] == 'contractor').length;
            final contractees = data.where((user) => user['role'] == 'contractee').length;

            return {
              'total': totalUsers,
              'contractors': contractors,
              'contractees': contractees,
            };
          });

      final projectStats = await _supabase
          .from('Projects')
          .select('status')
          .then((response) {
            final data = response as List<dynamic>;
            final totalProjects = data.length;
            final activeProjects = data.where((project) => project['status'] == 'active').length;
            final completedProjects = data.where((project) => project['status'] == 'completed').length;

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
        errorMessage: 'Failed to fetch system statistics: $e',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch System Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch system statistics: $e');
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
        errorMessage: 'Failed to fetch dashboard data: $e',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Dashboard Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  static Future<Map<String, dynamic>> getSystemHealthStatus() async {
    try {
      final checks = [
        {
          'component': 'database',
          'status': 'healthy',
          'response_time_ms': 45,
        },
        {
          'component': 'api_server',
          'status': 'healthy',
          'response_time_ms': 23,
        },
        {
          'component': 'file_storage',
          'status': 'healthy',
          'response_time_ms': 67,
        },
      ];

      final overallStatus = checks.any((check) => check['status'] == 'error')
          ? 'error'
          : checks.any((check) => check['status'] == 'warning')
              ? 'warning'
              : 'healthy';

      return {
        'overall_status': overallStatus,
        'checks': checks,
      };
    } catch (e) {
        SuperAdminErrorService().logError(
          errorMessage: 'Failed to fetch system health status: $e',
          module: 'Super Admin Service',
          severity: 'Medium',
          extraInfo: {
            'operation': 'Fetch System Health Status',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      throw Exception('Failed to fetch system health status: $e');
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

      return errorLogs.map((log) => {
        'error_id': log['error_id'],
        'error_message': log['error_message'],
        'severity': log['severity'],
        'module': log['module'],
        'timestamp': log['timestamp'],
      }).toList();
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch system alerts: $e',
        module: 'Super Admin Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch System Alerts',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch system alerts: $e');
    }
  }

  static Future<Map<String, dynamic>> getBackendPerformanceMetrics() async {
    try {
      final recentPerfLogs = await _supabase
          .from('PerfLogs')
          .select('metric_name, metric_value, unit, recorded_at, source')
          .order('recorded_at', ascending: false)
          .limit(50)
          .then((response) => response);

      final metrics = [
        {
          'metric': 'api_response_times',
          'status': 'good',
          'average_ms': _calculateAverage(recentPerfLogs, 'api_response_time'),
          'p95_ms': _calculatePercentile(
            recentPerfLogs
                .where((log) => log['metric_name'] == 'api_response_time')
                .map((log) => log['metric_value'] as num)
                .toList(),
            95
          ),
        },
        {
          'metric': 'database_query_times', 
          'status': 'good',
          'average_ms': _calculateAverage(recentPerfLogs, 'db_query_time'),
          'p95_ms': _calculatePercentile(
            recentPerfLogs
                .where((log) => log['metric_name'] == 'db_query_time')
                .map((log) => log['metric_value'] as num)
                .toList(),
            95
          ),
        },
        {
          'metric': 'error_rates',
          'status': 'warning',
          'error_rate_percent': _calculateAverage(recentPerfLogs, 'error_rate'),
        },
        {
          'metric': 'throughput',
          'status': 'good', 
          'requests_per_hour': _calculateRequestsPerHour(recentPerfLogs),
        },
      ];

      return {
        'metrics': metrics,
        'recent_logs': recentPerfLogs.take(10).toList(),
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

  static double _calculatePercentile(List<num> values, int percentile) {
    if (values.isEmpty) return 0.0;
    final sorted = List<num>.from(values)..sort();
    final index = (percentile / 100 * (sorted.length - 1)).round();
    return sorted[index].toDouble();
  }

  static int _calculateRequestsPerHour(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final recentRequests = logs.where((log) {
      final recordedAt = DateTime.parse(log['recorded_at']);
      return recordedAt.isAfter(oneHourAgo) && log['metric_name'] == 'api_request';
    }).length;

    return recentRequests;
  }

  static double _calculateAverage(List<Map<String, dynamic>> logs, String metricName) {
    final values = logs
        .where((log) => log['metric_name'] == metricName)
        .map((log) => log['metric_value'] as num)
        .toList();
    
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
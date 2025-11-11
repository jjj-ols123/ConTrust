import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/monitor_service.dart';
import 'package:backend/utils/be_datetime_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminServiceBackend {
  static final SystemMonitorService _monitorService = SystemMonitorService();
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
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
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
          'timestamp': DateTimeHelper.getLocalTimeISOString(),
        },
      );
      throw Exception('Failed to fetch dashboard data: ');
    }
  }

  static Future<List<Map<String, dynamic>>> getSystemAlerts() async {
    return await _monitorService.getSystemAlerts();
  }

  static Future<Map<String, dynamic>> getSystemHealthStatus() async {
    return await _monitorService.getSystemHealth();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class SuperAdminPerfLogsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllPerfLogs() async {
    try {
      final response = await _supabase
          .from('PerfLogs')
          .select('*')
          .order('recorded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to fetch all performance logs: ',
        module: 'Super Admin Perf Logs',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch All Perf Logs',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw Exception('Failed to fetch performance logs: ');
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
}
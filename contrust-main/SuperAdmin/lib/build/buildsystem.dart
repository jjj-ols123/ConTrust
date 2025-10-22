// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:backend/services/superadmin%20services/superadmin_service.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/services/superadmin services/perflogs_service.dart';

class BuildSystemMonitor {
  static Widget buildSystemOverviewCard(BuildContext context, Map<String, dynamic> healthData, VoidCallback? onRefresh) {
    final overallStatus = healthData['overall_status'] ?? 'unknown';
    final statusColor = _getStatusColor(overallStatus);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'System Overview',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    overallStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRefresh != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                    tooltip: 'Refresh Overview',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (healthData['checks'] != null)
              ...((healthData['checks'] as List).map((check) => buildHealthCheckItem(check))),
          ],
        ),
      ),
    );
  }

  static Widget buildHealthCheckItem(Map<String, dynamic> check) {
    final status = check['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status == 'healthy' ? Icons.check_circle_outline :
            status == 'warning' ? Icons.warning_outlined :
            status == 'error' ? Icons.error_outline :
            status == 'slow' ? Icons.access_time_outlined :
            Icons.help_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (check['component'] as String).replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  static Widget buildPerformanceMetricsCard(BuildContext context, Map<String, dynamic> performanceData, VoidCallback? onRefresh) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Performance Metrics',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                    tooltip: 'Refresh Metrics',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (performanceData['metrics'] != null)
              ...((performanceData['metrics'] as List).map((metric) => buildMetricItem(metric))),
          ],
        ),
      ),
    );
  }

  static Widget buildMetricItem(Map<String, dynamic> metric) {
    final status = metric['status'] ?? 'unknown';
    final statusColor = status == 'good' ? Colors.green :
                       status == 'warning' ? Colors.orange :
                       status == 'error' ? Colors.red : Colors.grey;
    
    final hasData = (metric['average_ms'] ?? 0) > 0 || 
                    (metric['requests_count'] ?? 0) > 0 ||
                    (metric['total_errors'] ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            metric['metric'] == 'api_response_times' ? Icons.api_outlined :
            metric['metric'] == 'database_query_times' ? Icons.storage_outlined :
            metric['metric'] == 'error_rates' ? Icons.error_outline :
            metric['metric'] == 'throughput' ? Icons.trending_up_outlined :
            Icons.analytics_outlined,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (metric['metric'] as String).replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasData ? status.toUpperCase() : 'NO DATA',
              style: TextStyle(
                color: hasData ? statusColor : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  static Widget buildSystemAlertsCard(List<Map<String, dynamic>> alerts, VoidCallback? onRefresh) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'System Alerts (${alerts.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                    tooltip: 'Refresh Alerts',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No active alerts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...alerts.map((alert) => buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  static Widget buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'low';
    final severityColor = severity == 'high' ? Colors.red :
                         severity == 'medium' ? Colors.orange : Colors.yellow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.warning_outlined, color: severityColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message'] ?? 'Unknown alert',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                Text(
                  alert['type']?.toString().toUpperCase() ?? 'SYSTEM',
                  style: TextStyle(fontSize: 10, color: severityColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  static Widget buildPerfLogsTable() {
    return const PerfLogsTable();
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'slow':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}

class SystemMonitorTable extends StatefulWidget {
  const SystemMonitorTable({super.key});

  @override
  SystemMonitorTableState createState() => SystemMonitorTableState();
}

class SystemMonitorTableState extends State<SystemMonitorTable> {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  Map<String, dynamic> _systemHealth = {};
  Map<String, dynamic> _performanceMetrics = {};
  List<Map<String, dynamic>> _systemAlerts = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadSystemData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadSystemData(silent: true);
      }
    });
  }

  Future<void> _loadSystemData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final results = await Future.wait([
       SuperAdminServiceBackend.getSystemHealthStatus(),
        SuperAdminServiceBackend.getBackendPerformanceMetrics(),
        SuperAdminServiceBackend.getSystemAlerts(),
      ]);

      if (mounted) {
        setState(() {
          _systemHealth = results[0] as Map<String, dynamic>;
          _performanceMetrics = results[1] as Map<String, dynamic>;
          _systemAlerts = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent) {
        await _errorService.logError(
          errorMessage: 'Failed to load system monitor data: ',
          module: 'Super Admin System Monitor',
          severity: 'High',
          extraInfo: {
            'operation': 'Load System Data',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSystemHealth() async {
    try {
      final health = await SuperAdminServiceBackend.getSystemHealthStatus();
      setState(() {
        _systemHealth = health;
      });
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to refresh system health: ',
        module: 'Super Admin System Monitor',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh System Health',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  Future<void> _refreshPerformanceMetrics() async {
    try {
      final metrics = await SuperAdminServiceBackend.getBackendPerformanceMetrics();
      setState(() {
        _performanceMetrics = metrics;
      });
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to refresh performance metrics: ',
        module: 'Super Admin System Monitor',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Performance Metrics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> _refreshSystemAlerts() async {
    try {
      final alerts = await SuperAdminServiceBackend.getSystemAlerts();
      setState(() {
        _systemAlerts = alerts;
      });
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to refresh system alerts: ',
        module: 'Super Admin System Monitor',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh System Alerts',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading system monitor...', style: TextStyle(color: Colors.black)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading system monitor',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSystemData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BuildSystemMonitor.buildSystemOverviewCard(context, _systemHealth, _refreshSystemHealth),
          const SizedBox(height: 16),
          BuildSystemMonitor.buildPerformanceMetricsCard(context, _performanceMetrics, _refreshPerformanceMetrics),
          const SizedBox(height: 16),
          BuildSystemMonitor.buildSystemAlertsCard(_systemAlerts, _refreshSystemAlerts),
        ],
      ),
    );
  }
}

class PerfLogsTable extends StatefulWidget {
  const PerfLogsTable({super.key});

  @override
  PerfLogsTableState createState() => PerfLogsTableState();
}

class PerfLogsTableState extends State<PerfLogsTable> {
  final SuperAdminPerfLogsService _perfLogsService = SuperAdminPerfLogsService();
  List<Map<String, dynamic>> _perfLogs = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadPerfLogs();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadPerfLogs(silent: true);
      }
    });
  }

  Future<void> _loadPerfLogs({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final logs = await _perfLogsService.getAllPerfLogs();
      
      if (mounted) {
        setState(() {
          _perfLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPerfLogs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Performance Logs (${_perfLogs.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadPerfLogs,
                        icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                        tooltip: 'Refresh Logs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_perfLogs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No performance logs found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Metric',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Unit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Source',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Recorded At',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                      rows: _perfLogs.map((log) {
                        return DataRow(cells: [
                          DataCell(Text(
                            log['metric_name'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          )),
                          DataCell(Text(
                            log['metric_value']?.toString() ?? '',
                            style: const TextStyle(color: Colors.black),
                          )),
                          DataCell(Text(
                            log['unit'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          )),
                          DataCell(Text(
                            log['source'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          )),
                          DataCell(Text(
                            log['recorded_at'] != null
                                ? DateTime.parse(log['recorded_at']).toString()
                                : '',
                            style: const TextStyle(color: Colors.black),
                          )),
                        ]);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

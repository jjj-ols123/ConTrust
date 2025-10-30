// ignore_for_file: unused_field, deprecated_member_use

import 'package:flutter/material.dart';

class BuildDashboard {
  static Widget buildSystemHealthCard(BuildContext context, Map<String, dynamic> systemHealth) {
    final overallStatus = systemHealth['overall_status'] ?? 'unknown';
    final statusColor = _getStatusColor(overallStatus);

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_outlined, color: Colors.grey, size: 28),
                const SizedBox(width: 8),
                Text(
                  'System Health',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
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
              ],
            ),
            const SizedBox(height: 16),
            if (systemHealth['checks'] != null)
              ...((systemHealth['checks'] as List).map((check) => buildHealthCheckItem(check))),
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
            status == 'error' ? Icons.error_outline : Icons.help_outline,
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

  static Widget buildAlertsCard(List<Map<String, dynamic>> systemAlerts) {
    if (systemAlerts.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_outlined, color: Colors.grey, size: 28),
                const SizedBox(width: 8),
                Text(
                  'System Alerts (${systemAlerts.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...systemAlerts.take(3).map((alert) => buildAlertItem(alert)),
            if (systemAlerts.length > 3)
              Text(
                '... and ${systemAlerts.length - 3} more alerts',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
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
                  alert['message'] ?? alert['error_message'] ?? 'Unknown alert',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alert['module'] != null)
                  Text(
                    alert['module'],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildMetricsGrid(BuildContext context, Map<String, dynamic> systemStats, Map<String, dynamic> systemHealth) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 13,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        buildMetricCard(
          'Total Users',
          systemStats['users']?['total']?.toString() ?? '0',
          Icons.people_outlined,
          Colors.grey,
        ),
        buildMetricCard(
          'Active Projects',
          systemStats['projects']?['active']?.toString() ?? '0',
          Icons.work_outlined,
          Colors.grey,
        ),
        buildMetricCard(
          'All Projects',
          systemStats['projects']?['total']?.toString() ?? '0',
          Icons.work_outline,
          Colors.grey,
        ),
        buildMetricCard(
          'System Status',
          systemHealth['overall_status']?.toString().toUpperCase() ?? 'UNKNOWN',
          Icons.health_and_safety_outlined,
          _getStatusColor(systemHealth['overall_status'] ?? 'unknown'),
        ),
      ],
    );
  }

  static Widget buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildPerformanceMetricsCard(Map<String, dynamic> performanceData) {
    final metrics = performanceData['metrics'] as List<dynamic>? ?? [];
    
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed_outlined, color: Colors.grey, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...metrics.map((metric) => buildPerformanceMetricItem(metric as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  static Widget buildPerformanceMetricItem(Map<String, dynamic> metric) {
    final status = metric['status'] ?? 'unknown';
    final statusColor = status == 'good' ? Colors.green :
                       status == 'warning' ? Colors.orange :
                       status == 'error' ? Colors.red : Colors.grey;
    final metricName = (metric['metric'] as String).replaceAll('_', ' ').toUpperCase();
    
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
            Icons.analytics_outlined,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metricName,
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

  static Widget buildDashboardLayout(
    BuildContext context,
    Map<String, dynamic> systemStats,
    Map<String, dynamic> systemHealth,
    List<Map<String, dynamic>> systemAlerts,
    Map<String, dynamic> dashboardData,
    {Map<String, dynamic>? performanceData}
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    Expanded(child: buildMetricsGrid(context, systemStats, systemHealth)),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 24),
                buildSystemHealthCard(context, systemHealth),
                const SizedBox(height: 24),
                // Performance Metrics - Hidden
                // if (performanceData != null)
                //   buildPerformanceMetricsCard(performanceData),
                // if (performanceData != null)
                //   const SizedBox(height: 24),
                buildAlertsCard(systemAlerts),
              ],
            ),
          ),
        ),
        Container(
          width: 350,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SingleChildScrollView(
            child: buildRecentActivitySection(context, dashboardData),
          ),
        ),
      ],
    );
  }

  static Widget buildRecentActivitySection(BuildContext context, Map<String, dynamic> dashboardData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            buildRecentUsersCard((dashboardData['recent_users'] as List? ?? []).cast<Map<String, dynamic>>()),
            const SizedBox(height: 16),
            buildRecentProjectsCard((dashboardData['recent_projects'] as List? ?? []).cast<Map<String, dynamic>>()),
            const SizedBox(height: 16),
            buildRecentAuditLogsCard(
              (dashboardData['recent_audit_logs'] as List? ?? []).cast<Map<String, dynamic>>(),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildRecentUsersCard(List<Map<String, dynamic>> recentUsers) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Recent Users', style: TextStyle(color: Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            if (recentUsers.isEmpty)
              const Text('No recent users', style: TextStyle(color: Colors.grey))
            else
              ...recentUsers.take(3).map((user) => buildUserListItem(user)),
          ],
        ),
      ),
    );
  }

  static Widget buildRecentProjectsCard(List<Map<String, dynamic>> recentProjects) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Recent Projects', style: TextStyle(color: Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            if (recentProjects.isEmpty)
              const Text('No recent projects', style: TextStyle(color: Colors.grey))
            else
              ...recentProjects.take(3).map((project) => buildProjectListItem(project)),
          ],
        ),
      ),
    );
  }

  static Widget buildRecentAuditLogsCard(List<Map<String, dynamic>> recentLogs) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Recent Audit Logs', style: TextStyle(color: Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
            if (recentLogs.isEmpty)
              const Text('No recent audit logs', style: TextStyle(color: Colors.grey))
            else
              ...recentLogs.take(5).map((log) => buildAuditLogItem(log)),
          ],
        ),
      ),
    );
  }

  static Widget buildUserListItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user['email'] ?? 'Unknown User',
              style: const TextStyle(fontSize: 14, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildProjectListItem(Map<String, dynamic> project) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.work_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Row(children: [
              const Icon(Icons.work_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['title'] ?? 'Untitled Project',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        color: _getStatusColor(project['status'] ?? 'unknown'),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  static Widget buildAuditLogItem(Map<String, dynamic> log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.history_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${log['action'] ?? 'Unknown action'} - ${log['category'] ?? 'general'}',
              style: const TextStyle(fontSize: 14, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
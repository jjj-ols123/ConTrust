// ignore_for_file: unused_field, deprecated_member_use

import 'package:flutter/material.dart';

class BuildDashboard {
  static Widget buildSystemHealthCard(
    BuildContext context,
    Map<String, dynamic> systemHealth,
  ) {
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
                Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Health',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.black),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
              ...((systemHealth['checks'] as List).map(
                (check) => buildHealthCheckItem(check),
              )),
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
            status == 'healthy'
                ? Icons.check_circle_outline
                : status == 'warning'
                ? Icons.warning_outlined
                : status == 'error'
                ? Icons.error_outline
                : Icons.help_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (check['component'] as String).replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
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
    return const SizedBox.shrink();
  }

  static Widget buildAlertItem(Map<String, dynamic> alert) {
    return const SizedBox.shrink();
  }

  static Widget buildMetricsGrid(
    BuildContext context,
    Map<String, dynamic> systemStats,
    Map<String, dynamic> systemHealth,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final totalUsers = systemStats['users']?['total']?.toString() ?? '0';
    final activeProjects =
        systemStats['projects']?['active']?.toString() ?? '0';
    final allProjects = systemStats['projects']?['total']?.toString() ?? '0';
    final status = systemHealth['overall_status']?.toString() ?? 'unknown';
    final statusText = status.toUpperCase();
    final statusColor = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF9E86FF)],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.bar_chart, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (isMobile)
            Column(
              children: [
                _buildDashboardStatCard(
                  'Total Users',
                  totalUsers,
                  Icons.people_outlined,
                  Colors.black,
                  isMobile,
                ),
                const SizedBox(height: 10),
                _buildDashboardStatCard(
                  'Active Projects',
                  activeProjects,
                  Icons.work,
                  Colors.black,
                  isMobile,
                ),
                const SizedBox(height: 10),
                _buildDashboardStatCard(
                  'All Projects',
                  allProjects,
                  Icons.work_outline,
                  Colors.black,
                  isMobile,
                ),
                const SizedBox(height: 10),
                _buildDashboardStatCard(
                  'System Status',
                  statusText,
                  Icons.health_and_safety_outlined,
                  statusColor,
                  isMobile,
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardStatCard(
                        'Total Users',
                        totalUsers,
                        Icons.people_outlined,
                        Colors.black,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDashboardStatCard(
                        'Active Projects',
                        activeProjects,
                        Icons.work,
                        Colors.black,
                        isMobile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardStatCard(
                        'All Projects',
                        allProjects,
                        Icons.work_outline,
                        Colors.black,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDashboardStatCard(
                        'System Status',
                        statusText,
                        Icons.health_and_safety_outlined,
                        statusColor,
                        isMobile,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _buildDashboardStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : null,
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          isMobile
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
    );
  }

  static Widget buildPerformanceMetricsCard(
    Map<String, dynamic> performanceData,
  ) {
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...metrics.map(
              (metric) =>
                  buildPerformanceMetricItem(metric as Map<String, dynamic>),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildPerformanceMetricItem(Map<String, dynamic> metric) {
    final status = metric['status'] ?? 'unknown';
    final statusColor =
        status == 'good'
            ? Colors.green
            : status == 'warning'
            ? Colors.orange
            : status == 'error'
            ? Colors.red
            : Colors.grey;
    final metricName =
        (metric['metric'] as String).replaceAll('_', ' ').toUpperCase();

    final hasData =
        (metric['average_ms'] ?? 0) > 0 ||
        (metric['requests_count'] ?? 0) > 0 ||
        (metric['total_errors'] ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            metric['metric'] == 'api_response_times'
                ? Icons.api_outlined
                : metric['metric'] == 'database_query_times'
                ? Icons.storage_outlined
                : metric['metric'] == 'error_rates'
                ? Icons.error_outline
                : Icons.analytics_outlined,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metricName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
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
    Map<String, dynamic> dashboardData, {
    Map<String, dynamic>? performanceData,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1000;

    if (!isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            buildMetricsGrid(context, systemStats, systemHealth),
            const SizedBox(height: 24),
            buildSystemHealthCard(context, systemHealth),
            const SizedBox(height: 24),
            // Recent Activity stacked below on narrow screens
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              padding: const EdgeInsets.only(top: 16),
              child: buildRecentActivitySection(context, dashboardData),
            ),
          ],
        ),
      );
    }

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
                    Expanded(
                      child: buildMetricsGrid(
                        context,
                        systemStats,
                        systemHealth,
                      ),
                    ),
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
                // System Alerts removed
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

  static Widget buildRecentActivitySection(
    BuildContext context,
    Map<String, dynamic> dashboardData,
  ) {
    final recentUsers =
        (dashboardData['recent_users'] as List? ?? [])
            .cast<Map<String, dynamic>>();
    final recentProjects =
        (dashboardData['recent_projects'] as List? ?? [])
            .cast<Map<String, dynamic>>();
    final recentLogs =
        (dashboardData['recent_audit_logs'] as List? ?? [])
            .cast<Map<String, dynamic>>();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.update, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          buildRecentUsersCard(recentUsers),
          const SizedBox(height: 12),
          buildRecentProjectsCard(recentProjects),
          const SizedBox(height: 12),
          buildRecentAuditLogsCard(recentLogs),
        ],
      );
    }

    final controller = PageController(viewportFraction: 0.92);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final current =
                controller.hasClients && controller.page != null
                    ? controller.page!.round()
                    : 0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous',
                    onPressed:
                        current > 0
                            ? () => controller.animateToPage(
                              current - 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            )
                            : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Next',
                    onPressed:
                        current < 2
                            ? () => controller.animateToPage(
                              current + 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            )
                            : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: PageView(
            controller: controller,
            children: [
              buildRecentUsersCard(recentUsers),
              buildRecentProjectsCard(recentProjects),
              buildRecentAuditLogsCard(recentLogs),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final page =
                  controller.hasClients && controller.page != null
                      ? controller.page!.round()
                      : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final isActive = index == page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 10 : 8,
                    height: isActive ? 10 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black87 : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
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
                const Text(
                  'Recent Users',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentUsers.isEmpty)
              const Text(
                'No recent users',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...recentUsers.take(3).map((user) => buildUserListItem(user)),
          ],
        ),
      ),
    );
  }

  static Widget buildRecentProjectsCard(
    List<Map<String, dynamic>> recentProjects,
  ) {
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
                const Text(
                  'Recent Projects',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentProjects.isEmpty)
              const Text(
                'No recent projects',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...recentProjects
                  .take(3)
                  .map((project) => buildProjectListItem(project)),
          ],
        ),
      ),
    );
  }

  static Widget buildRecentAuditLogsCard(
    List<Map<String, dynamic>> recentLogs,
  ) {
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
                const Text(
                  'Recent Audit Logs',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentLogs.isEmpty)
              const Text(
                'No recent audit logs',
                style: TextStyle(color: Colors.grey),
              )
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
            child: Row(
              children: [
                const Icon(Icons.work_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] ?? 'Untitled Project',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project['status']?.toString().toUpperCase() ??
                            'UNKNOWN',
                        style: TextStyle(
                          color: _getStatusColor(
                            project['status'] ?? 'unknown',
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:backend/utils/be_contractformat.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildError {
  static Widget buildErrorStatisticsCard(BuildContext context, Map<String, dynamic> stats, VoidCallback? onRefresh) {
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
                const Icon(Icons.error_outline, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Error Statistics',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                    tooltip: 'Refresh Statistics',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Errors',
                    stats['total_logs']?.toString() ?? '0',
                    Icons.bug_report_outlined,
                    Colors.red.shade300,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Unresolved',
                    stats['unresolved_count']?.toString() ?? '0',
                    Icons.warning_outlined,
                    Colors.orange.shade300,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Modules',
                    (stats['module_counts'] as Map<String, dynamic>?)?.length.toString() ?? '0',
                    Icons.category_outlined,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildErrorFilters(BuildContext context, ErrorLogsTableState state) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Search by error message, module, or user...',
                      prefixIcon: const Icon(Icons.search_outlined, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      labelStyle: const TextStyle(color: Colors.black),
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => state.filterLogs(value),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: state.selectedSeverity,
                  hint: const Text('Severity', style: TextStyle(color: Colors.black)),
                  items: ['All', 'low', 'medium', 'high', 'critical']
                      .map((severity) => DropdownMenuItem(
                            value: severity,
                            child: Text(severity == 'All' ? 'All Severities' : severity.toUpperCase(), style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (value) => state.filterBySeverity(value!),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: state.selectedStatus,
                  hint: const Text('Status', style: TextStyle(color: Colors.black)),
                  items: ['All', 'resolved', 'unresolved']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status == 'All' ? 'All Status' : status.toUpperCase(), style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (value) => state.filterByStatus(value!),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: state.clearFilters,
                  icon: const Icon(Icons.clear_outlined),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorLogsTable extends StatefulWidget {
  const ErrorLogsTable({super.key});

  @override
  ErrorLogsTableState createState() => ErrorLogsTableState();
}

class ErrorLogsTableState extends State<ErrorLogsTable> {
  final SuperAdminErrorService _errorService = SuperAdminErrorService();
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String selectedSeverity = 'All';
  String selectedStatus = 'All';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadErrorData();
  }

  Future<void> _loadErrorData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _errorService.getRecentErrorLogs(limit: 1000),
        _errorService.getErrorStatistics(),
      ]);

      setState(() {
        _allLogs = results[0] as List<Map<String, dynamic>>;
        _filteredLogs = List.from(_allLogs);
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to load error data: ',
        module: 'Super Admin Error Logs',
        severity: 'High',
        extraInfo: {
          'operation': 'Load Error Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshErrorStatistics() async {
    try {
      final stats = await _errorService.getErrorStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh error statistics: ',
        module: 'Super Admin Error Logs',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Error Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> _refreshErrorLogs() async {
    try {
      final logs = await _errorService.getRecentErrorLogs(limit: 1000);
      setState(() {
        _allLogs = logs;
        _filteredLogs = List.from(_allLogs);
        _applyFilters();
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh error logs: ',
        module: 'Super Admin Error Logs',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Error Logs',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void filterLogs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void filterBySeverity(String severity) {
    setState(() {
      selectedSeverity = severity;
      _applyFilters();
    });
  }

  void filterByStatus(String status) {
    setState(() {
      selectedStatus = status;
      _applyFilters();
    });
  }

  void clearFilters() {
    setState(() {
      _searchQuery = '';
      selectedSeverity = 'All';
      selectedStatus = 'All';
      _filteredLogs = List.from(_allLogs);
    });
  }

  void _applyFilters() {
    _filteredLogs = _allLogs.where((log) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          (log['error_message']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (log['users_id']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (log['module']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (log['stack_trace']?.toString().toLowerCase().contains(_searchQuery) ?? false);

      // Severity filter (case-insensitive)
      final logSeverity = log['severity']?.toString().toLowerCase() ?? '';
      final selectedSeverityLower = selectedSeverity.toLowerCase();
      final matchesSeverity = selectedSeverity == 'All' ||
          logSeverity == selectedSeverityLower;

      final matchesStatus = selectedStatus == 'All' ||
          (selectedStatus == 'resolved' && log['resolved'] == true) ||
          (selectedStatus == 'unresolved' && log['resolved'] == false);

      return matchesSearch && matchesSeverity && matchesStatus;
    }).toList();
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
            Text('Loading error logs...', style: TextStyle(color: Colors.black)),
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
              'Error loading error logs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadErrorData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        BuildError.buildErrorStatisticsCard(context, _statistics, _refreshErrorStatistics),
        BuildError.buildErrorFilters(context, this),
        Expanded(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Error Logs (${_filteredLogs.length})',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _refreshErrorLogs,
                        icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                        tooltip: 'Refresh Logs',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredLogs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                              SizedBox(height: 16),
                              Text('No error logs found', style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      columnSpacing: 32,
                                      columns: const [
                                        DataColumn(label: Text('Resolved', style: TextStyle(color: Colors.black))),
                                        DataColumn(label: Text('Timestamp', style: TextStyle(color: Colors.black))),
                                        DataColumn(label: Text('Severity', style: TextStyle(color: Colors.black))),
                                        DataColumn(label: Text('Module', style: TextStyle(color: Colors.black))),
                                        DataColumn(label: Text('Message', style: TextStyle(color: Colors.black))),
                                      ],
                                      rows: _filteredLogs.map((log) => DataRow(
                                        cells: [
                                          DataCell(
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Checkbox(
                                                value: log['resolved'] ?? false,
                                                onChanged: (value) async {
                                                  try {
                                                    if (value == true) {
                                                      await _errorService.markErrorResolved(log['error_id'].toString());
                                                    } else {
                                                      await _errorService.markErrorUnresolved(log['error_id'].toString());
                                                    }
                                                    setState(() {
                                                      log['resolved'] = value;
                                                    });
                                                    await _refreshErrorStatistics();
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to update resolved status: ')),
                                                    );
                                                  }
                                                },
                                                activeColor: Colors.green,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(ContractStyle().formatTimestamp(log['timestamp']), style: const TextStyle(color: Colors.black))),
                                          DataCell(_buildSeverityChip(log['severity']?.toString() ?? 'medium')),
                                          DataCell(Text(log['module']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black))),
                                          DataCell(
                                            Text(
                                              log['error_message']?.toString() ?? 'N/A',
                                              style: const TextStyle(color: Colors.black),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      )).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityChip(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'low':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'high':
        color = Colors.red;
        break;
      case 'critical':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        severity.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
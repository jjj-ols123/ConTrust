// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildAudit {
  final SuperAdminErrorService errorService = SuperAdminErrorService(); 

  static Widget buildAuditLogsTable(BuildContext context) {
    return AuditLogsTable();
  }

  static Widget buildAuditStatisticsCard(BuildContext context, Map<String, dynamic> stats, VoidCallback? onRefresh) {
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
                const Icon(Icons.analytics_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Audit Statistics',
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
                    'Total Logs',
                    stats['total_logs']?.toString() ?? '0',
                    Icons.history_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Categories',
                    (stats['category_counts'] as Map<String, dynamic>?)?.length.toString() ?? '0',
                    Icons.category_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Actions',
                    (stats['action_counts'] as Map<String, dynamic>?)?.length.toString() ?? '0',
                    Icons.touch_app_outlined,
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

  static Widget buildAuditFilters(BuildContext context, AuditLogsTableState state) {
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
                      hintText: 'Search by action, user, or details...',
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
                  value: state.selectedCategory,
                  hint: const Text('Category', style: TextStyle(color: Colors.black)),
                  items: ['All', 'admin', 'user', 'system', 'security', 'error']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category == 'All' ? 'All Categories' : category.toUpperCase(), style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (value) => state.filterByCategory(value!),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: state.selectedAction,
                  hint: const Text('Action', style: TextStyle(color: Colors.black)),
                  items: ['All', 'login', 'logout', 'create', 'update', 'delete', 'view']
                      .map((action) => DropdownMenuItem(
                            value: action,
                            child: Text(action == 'All' ? 'All Actions' : action.toUpperCase(), style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (value) => state.filterByAction(value!),
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

class AuditLogsTable extends StatefulWidget {
  const AuditLogsTable({super.key});

  @override
  AuditLogsTableState createState() => AuditLogsTableState();
}

class AuditLogsTableState extends State<AuditLogsTable> {
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String selectedCategory = 'All';
  String selectedAction = 'All';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAuditData();
  }

  Future<void> _loadAuditData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _auditService.getRecentAuditLogs(limit: 500), 
        _auditService.getAuditStatistics(),
      ]);

      setState(() {
        _allLogs = results[0] as List<Map<String, dynamic>>;
        _filteredLogs = List.from(_allLogs);
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to load audit data: ',
        module: 'Super Admin Audit Logs',
        severity: 'High',
        extraInfo: {
          'operation': 'Load Audit Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAuditStatistics() async {
    try {
      final stats = await _auditService.getAuditStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh audit statistics:',
        module: 'Super Admin Audit Logs',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Audit Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  Future<void> _refreshAuditLogs() async {
    try {
      final logs = await _auditService.getRecentAuditLogs(limit: 500); // Reduced refresh load
      setState(() {
        _allLogs = logs;
        _filteredLogs = List.from(_allLogs);
        _applyFilters();
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh audit logs: $e',
        module: 'Super Admin Audit Logs',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Audit Logs',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  void filterLogs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      _applyFilters();
    });
  }

  void filterByAction(String action) {
    setState(() {
      selectedAction = action;
      _applyFilters();
    });
  }

  void clearFilters() {
    setState(() {
      _searchQuery = '';
      selectedCategory = 'All';
      selectedAction = 'All';
      _filteredLogs = List.from(_allLogs);
    });
  }

  void _applyFilters() {
    _filteredLogs = _allLogs.where((log) {

      final matchesSearch = _searchQuery.isEmpty ||
          (log['action']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (log['users_id']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (log['details']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (log['category']?.toString().toLowerCase().contains(_searchQuery) ?? false);

      final matchesCategory = selectedCategory == 'All' ||
          log['category'] == selectedCategory;

      final matchesAction = selectedAction == 'All' ||
          log['action'] == selectedAction;

      return matchesSearch && matchesCategory && matchesAction;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text('Loading audit logs...', style: TextStyle(color: Colors.black)),
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
              'Error loading audit logs',
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
              onPressed: _loadAuditData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        BuildAudit.buildAuditStatisticsCard(context, _statistics, _refreshAuditStatistics),
        BuildAudit.buildAuditFilters(context, this),
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
                        'Audit Logs (${_filteredLogs.length})',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _refreshAuditLogs,
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
                              Icon(Icons.history_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No audit logs found', style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Timestamp', style: TextStyle(color: Colors.black))),
                              DataColumn(label: Text('User ID', style: TextStyle(color: Colors.black))),
                              DataColumn(label: Text('Action', style: TextStyle(color: Colors.black))),
                              DataColumn(label: Text('Category', style: TextStyle(color: Colors.black))),
                              DataColumn(label: Text('Details', style: TextStyle(color: Colors.black))),
                            ],
                            rows: _filteredLogs.map((log) => DataRow(
                              cells: [
                                DataCell(Text(formatTimestamp(log['timestamp']), style: const TextStyle(color: Colors.black))),
                                DataCell(Text(log['users_id']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black))),
                                DataCell(_buildActionChip(log['action']?.toString() ?? 'unknown')),
                                DataCell(_buildCategoryChip(log['category']?.toString() ?? 'unknown')),
                                DataCell(
                                  Text(
                                    _formatDetails(log['details']),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            )).toList(),
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

  String formatTimestamp(String? timestamp) {
  if (timestamp == null) return 'N/A';
  try {
    final dateTime = DateTime.parse(timestamp).toLocal();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return timestamp;
  }
}

  String _formatDetails(dynamic details) {
    if (details == null) return 'N/A';
    if (details is String) return details;
    if (details is Map) {
      return details['description']?.toString() ?? details.toString();
    }
    return details.toString();
  }

  Widget _buildActionChip(String action) {
    Color color;
    switch (action.toLowerCase()) {
      case 'login':
        color = Colors.green;
        break;
      case 'logout':
        color = Colors.grey;
        break;
      case 'create':
        color = Colors.blue;
        break;
      case 'update':
        color = Colors.orange;
        break;
      case 'delete':
        color = Colors.red;
        break;
      case 'view':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        action.toUpperCase(),
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

  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category.toLowerCase()) {
      case 'admin':
        color = Colors.deepPurple;
        break;
      case 'user':
        color = Colors.blue;
        break;
      case 'system':
        color = Colors.teal;
        break;
      case 'security':
        color = Colors.red;
        break;
      case 'error':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        category.toUpperCase(),
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
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/project_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildProjects {

  static Widget buildProjectStatisticsCard(BuildContext context, Map<String, int> stats, VoidCallback? onRefresh) {
    final total = stats['total'] ?? 0;
    
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics_outlined, color: Colors.grey.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Project Statistics',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const Spacer(),
                _buildAutoRefreshBadge(),
                const SizedBox(width: 8),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(Icons.refresh_outlined, color: Colors.grey.shade600),
                    tooltip: 'Refresh Statistics',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Projects',
                    total.toString(),
                    Icons.work_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Active',
                    stats['active']?.toString() ?? '0',
                    Icons.trending_up_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    stats['completed']?.toString() ?? '0',
                    Icons.check_circle_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    stats['pending']?.toString() ?? '0',
                    Icons.pending_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget _buildAutoRefreshBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.autorenew, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            '10s',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildProjectsFilters(BuildContext context, ProjectsManagementTableState state) {
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
                      hintText: 'Search by title, contractor, or contractee...',
                      prefixIcon: const Icon(Icons.search_outlined, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      labelStyle: const TextStyle(color: Colors.black),
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => state.filterProjects(value),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: state.selectedStatus,
                  dropdownColor: Colors.white,
                  hint: const Text('Status', style: TextStyle(color: Colors.black)),
                  items: ['All', 'active', 'completed', 'pending', 'cancelled']
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

  static Widget buildProjectsGrid(BuildContext context, List<Map<String, dynamic>> projects, bool isLoading, VoidCallback onRefresh) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
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
                  'Projects (${projects.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                  tooltip: 'Refresh Projects',
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading projects...', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  )
                : projects.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No projects found', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 1200 ? 3 : screenWidth > 800 ? 2 : 1,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: screenWidth > 1200 ? 1.5 : 1.8,
                  ),
                  itemBuilder: (ctx, index) {
                    final project = projects[index];
                    return buildProjectCard(context, project);
                  },
                ),
          ),
        ],
      ),
    );
  }

  static Widget buildProjectCard(BuildContext context, Map<String, dynamic> project) {
    final status = project['status'] ?? 'unknown';
    final contractor = project['contractor'] is List && (project['contractor'] as List).isNotEmpty
        ? (project['contractor'] as List).first
        : project['contractor'];
    final contractee = project['contractee'] is List && (project['contractee'] as List).isNotEmpty
        ? (project['contractee'] as List).first
        : project['contractee'];

    final contractorName = contractor != null ? contractor['firm_name'] ?? 'Unassigned' : 'Unassigned';
    final contracteeName = contractee != null ? contractee['full_name'] ?? 'Unknown Client' : 'Unknown Client';
    final location = project['location'] ?? 'No location';
    final startDate = project['start_date'] != null ? _formatDate(project['start_date']) : 'Not set';

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.work_outline, color: Colors.grey.shade700, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['title'] ?? 'Untitled Project',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400, width: 1),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.business_outlined, contractorName),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.person_outlined, contracteeName),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.location_on_outlined, location),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.calendar_today_outlined, 'Start: $startDate'),
              const Spacer(),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.money, size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '₱${project['min_budget']?.toString() ?? 'N/A'} - ₱${project['max_budget']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_outlined, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(project['created_at']),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to parse date: $dateString, error: ',
        module: 'Super Admin Projects',
        severity: 'Low',
        extraInfo: {
          'operation': 'Format Date',
          'dateString': dateString,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return dateString;
    }
  }

}

class ProjectsManagementTable extends StatefulWidget {
  const ProjectsManagementTable({super.key});

  @override
  ProjectsManagementTableState createState() => ProjectsManagementTableState();
}

class ProjectsManagementTableState extends State<ProjectsManagementTable> {
  final SuperAdminProjectService _projectService = SuperAdminProjectService();
  List<Map<String, dynamic>> _allProjects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String selectedStatus = 'All';
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadProjectData(silent: true);
      }
    });
  }

  Future<void> _loadProjectData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final results = await Future.wait([
        _projectService.getAllProjects(),
        _projectService.getProjectStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _allProjects = results[0] as List<Map<String, dynamic>>;
          _filteredProjects = List.from(_allProjects);
          _statistics = results[1] as Map<String, int>;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (!silent) {
        await SuperAdminErrorService().logError(
          errorMessage: 'Failed to load project data: ',
          module: 'Super Admin Projects',
          severity: 'High',
          extraInfo: {
            'operation': 'Load Project Data',
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

  Future<void> _refreshStatistics() async {
    try {
      final stats = await _projectService.getProjectStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh project statistics: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Project Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      SuperAdminErrorService().logError(
        errorMessage: 'Error Refreshing Project Statistics: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Project Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> _refreshProjects() async {
    try {
      final projects = await _projectService.getAllProjects();
      setState(() {
        _allProjects = projects;
        _filteredProjects = List.from(_allProjects);
        _applyFilters();
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh projects: ',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Projects',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void filterProjects(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
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
      selectedStatus = 'All';
      _filteredProjects = List.from(_allProjects);
    });
  }

  void _applyFilters() {
    _filteredProjects = _allProjects.where((project) {
      final matchesSearch = _searchQuery.isEmpty ||
          (project['title']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (project['description']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (project['contractor']?['name']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (project['contractee']?['name']?.toString().toLowerCase().contains(_searchQuery) ?? false);

      final matchesStatus = selectedStatus == 'All' ||
          project['status'] == selectedStatus;

      return matchesSearch && matchesStatus;
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
            Text('Loading projects...', style: TextStyle(color: Colors.black)),
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
              'Error loading projects',
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
              onPressed: _loadProjectData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        BuildProjects.buildProjectStatisticsCard(context, _statistics, _refreshStatistics),
        BuildProjects.buildProjectsFilters(context, this),
        Expanded(
          child: BuildProjects.buildProjectsGrid(context, _filteredProjects, false, _refreshProjects),
        ),
      ],
    );
  }
}

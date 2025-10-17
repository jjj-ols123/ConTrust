// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/project_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildProjects {

  static Widget buildProjectStatisticsCard(BuildContext context, Map<String, int> stats, VoidCallback? onRefresh) {
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
                const Icon(Icons.work_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Project Statistics',
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
                    'Total Projects',
                    stats['total']?.toString() ?? '0',
                    Icons.work_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Active',
                    stats['active']?.toString() ?? '0',
                    Icons.play_circle_outlined,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    stats['completed']?.toString() ?? '0',
                    Icons.check_circle_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    stats['pending']?.toString() ?? '0',
                    Icons.pending_outlined,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
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
                    childAspectRatio: screenWidth > 1200 ? 1.2 : 1.4,
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
    final statusColor = _getStatusColor(project['status'] ?? 'unknown');

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project['title'] ?? 'Untitled Project',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (project['status'] ?? 'unknown').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['description'] ?? 'No description available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project['contractor']?['name'] ?? 'Unknown Contractor',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project['contractee']?['name'] ?? 'Unknown Contractee',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Budget: ₱${project['budget']?.toString() ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(project['created_at']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      SuperAdminErrorService().logError(
        errorMessage: 'Failed to parse date: $dateString, error: $e',
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

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _projectService.getAllProjects(),
        _projectService.getProjectStatistics(),
      ]);

      setState(() {
        _allProjects = results[0] as List<Map<String, dynamic>>;
        _filteredProjects = List.from(_allProjects);
        _statistics = results[1] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to load project data: $e',
        module: 'Super Admin Projects',
        severity: 'High',
        extraInfo: {
          'operation': 'Load Project Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        errorMessage: 'Failed to refresh project statistics: $e',
        module: 'Super Admin Projects',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Project Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      SuperAdminErrorService().logError(
        errorMessage: 'Error Refreshing Project Statistics: $e',
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
        errorMessage: 'Failed to refresh projects: $e',
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

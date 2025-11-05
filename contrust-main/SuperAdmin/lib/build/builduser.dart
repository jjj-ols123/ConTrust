// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/userlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildUser {
  final SuperAdminErrorService errorService = SuperAdminErrorService();

  static Widget buildUserStatisticsCard(BuildContext context, Map<String, dynamic> stats, VoidCallback? onRefresh) {
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
                const Icon(Icons.people_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  'User Statistics',
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
                    'All Users',
                    stats['total']?.toString() ?? '0',
                    Icons.group_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Contractors',
                    stats['contractors']?.toString() ?? '0',
                    Icons.business_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Contractees',
                    stats['contractees']?.toString() ?? '0',
                    Icons.person_outlined,
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

  static Widget buildUserFilters(BuildContext context, UserTableState state) {
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
                      hintText: 'Search by name, email, or role...',
                      prefixIcon: const Icon(Icons.search_outlined, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      labelStyle: const TextStyle(color: Colors.black),
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    onChanged: (value) => state.filterUsers(value),
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

class UserTable extends StatefulWidget {
  const UserTable({super.key});

  @override
  UserTableState createState() => UserTableState();
}

class UserTableState extends State<UserTable> with SingleTickerProviderStateMixin {
  final SuperAdminUserService _userService = SuperAdminUserService();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _contractors = [];
  List<Map<String, dynamic>> _contractees = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String selectedRole = 'All';
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final contractors = await _userService.getUsersByRole('contractor');
      final contractees = await _userService.getUsersByRole('contractee');
      final stats = await _userService.getUserStatistics();

      setState(() {
        _allUsers = [...contractors, ...contractees];
        _contractors = contractors;
        _contractees = contractees;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to load user data: ',
        module: 'Super Admin Users',
        severity: 'High',
        extraInfo: {
          'operation': 'Load User Data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUserStatistics() async {
    try {
      final stats = await _userService.getUserStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh user statistics: ',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh User Statistics',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  void filterUsers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void filterByRole(String role) {
    setState(() {
      selectedRole = role;
      _applyFilters();
    });
  }

  void clearFilters() {
    setState(() {
      _searchQuery = '';
      selectedRole = 'All';
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _allUsers.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          (user['name']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (user['email']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
          (user['role']?.toString().toLowerCase().contains(_searchQuery) ?? false);

      final matchesRole = selectedRole == 'All' || user['role'] == selectedRole;

      return matchesSearch && matchesRole;
    }).toList();

    _contractors = filtered.where((user) => user['role'] == 'contractor').toList();
    _contractees = filtered.where((user) => user['role'] == 'contractee').toList();
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
            Text('Loading users...', style: TextStyle(color: Colors.black)),
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
              'Error loading users',
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
              onPressed: _loadUserData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        BuildUser.buildUserStatisticsCard(context, _statistics, _refreshUserStatistics),
        BuildUser.buildUserFilters(context, this),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Contractors'),
                    Tab(text: 'Contractees'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserTable(_contractors, 'Contractors'),
                      _buildUserTable(_contractees, 'Contractees'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTable(List<Map<String, dynamic>> users, String title) {
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
                  '$title (${users.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadUserData,
                  icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                  tooltip: 'Refresh Users',
                ),
              ],
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No users found', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 15,
                              headingRowHeight: 56,
                              dataRowHeight: 56,
                              columns: const [
                                DataColumn(label: Text('Name', style: TextStyle(color: Colors.black))),
                                DataColumn(label: Text('Email', style: TextStyle(color: Colors.black))),
                                DataColumn(label: Text('Role', style: TextStyle(color: Colors.black))),
                                DataColumn(label: Text('Last Login', style: TextStyle(color: Colors.black))),
                              ],
                              rows: users.map((user) => DataRow(
                                cells: [
                                  DataCell(Text(user['name']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black))),
                                  DataCell(Text(user['email']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black))),
                                  DataCell(_buildRoleChip(user['role']?.toString() ?? 'unknown')),
                                  DataCell(Text(_formatLastLogin(user['last_login']), style: const TextStyle(color: Colors.black))),
                                ],
                              )).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'contractor':
        color = Colors.green;
        break;
      case 'contractee':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        role.toUpperCase(),
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

  String _formatLastLogin(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime dt;
      if (timestamp is String) {
        dt = DateTime.parse(timestamp).toLocal();
      } else if (timestamp is DateTime) {
        dt = timestamp.toLocal();
      } else {
        if (timestamp is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
        } else {
          return timestamp.toString();
        }
      }
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
             '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}
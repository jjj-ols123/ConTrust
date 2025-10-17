// ignore_for_file: deprecated_member_use

import 'package:backend/services/superadmin%20services/userlogs_service.dart';
import 'package:backend/utils/be_contractformat.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';

class BuildUsers {
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
                    'Total Users',
                    stats['total']?.toString() ?? '0',
                    Icons.people_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Contractors',
                    stats['contractors']?.toString() ?? '0',
                    Icons.business_outlined,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
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

  static Widget buildUsersTable(BuildContext context, String title, List<Map<String, dynamic>> users, VoidCallback? onRefresh) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero, // Remove space at the sides
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
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
                    tooltip: 'Refresh $title',
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
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name', style: TextStyle(color: Colors.black))),
                        DataColumn(label: Text('Email', style: TextStyle(color: Colors.black))),
                        DataColumn(label: Text('Status', style: TextStyle(color: Colors.black))),
                        DataColumn(label: Text('Verified', style: TextStyle(color: Colors.black))),
                        DataColumn(label: Text('Created', style: TextStyle(color: Colors.black))),
                        DataColumn(label: Text('Last Login', style: TextStyle(color: Colors.black))), // New column
                      ],
                      rows: users.map((user) => DataRow(
                        cells: [
                          DataCell(Text(user['name']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black))),
                          DataCell(Text(user['email']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.black))),
                          DataCell(_buildStatusChip(user['status']?.toString() ?? 'unknown')),
                          DataCell(_buildVerificationChip(user['verified'] ?? false)),
                          DataCell(Text(ContractStyle.formatDate(user['created_at']), style: const TextStyle(color: Colors.black))),
                          DataCell(Text(ContractStyle().formatTimestamp(user['last_login']), style: const TextStyle(color: Colors.black))), // New cell
                        ],
                      )).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      case 'suspended':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
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

  static Widget _buildVerificationChip(bool verified) {
    return Chip(
      label: Text(
        verified ? 'VERIFIED' : 'PENDING',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: verified ? Colors.blue : Colors.orange,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class UsersManagementTable extends StatefulWidget {
  const UsersManagementTable({super.key});

  @override
  UsersManagementTableState createState() => UsersManagementTableState();
}

class UsersManagementTableState extends State<UsersManagementTable> {
  final SuperAdminUserService _userService = SuperAdminUserService();
  List<Map<String, dynamic>> _contractors = [];
  List<Map<String, dynamic>> _contractees = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _userService.getUsersByRole('contractor'),
        _userService.getUsersByRole('contractee'),
        _userService.getUserStatistics(),
      ]);

      setState(() {
        _contractors = results[0] as List<Map<String, dynamic>>;
        _contractees = results[1] as List<Map<String, dynamic>>;
        _statistics = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to load user data: $e',
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

  Future<void> _refreshStatistics() async {
    try {
      final stats = await _userService.getUserStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh user statistics: $e',
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

  Future<void> _refreshContractors() async {
    try {
      final contractors = await _userService.getUsersByRole('contractor');
      setState(() {
        _contractors = contractors;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh contractors: $e',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Contractors',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> _refreshContractees() async {
    try {
      final contractees = await _userService.getUsersByRole('contractee');
      setState(() {
        _contractees = contractees;
      });
    } catch (e) {
      await SuperAdminErrorService().logError(
        errorMessage: 'Failed to refresh contractees: $e',
        module: 'Super Admin Users',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Refresh Contractees',
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
              onPressed: _loadUserData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        BuildUsers.buildUserStatisticsCard(context, _statistics, _refreshStatistics),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: BuildUsers.buildUsersTable(context, 'Contractors', _contractors, _refreshContractors),
              ),
              const SizedBox(width: 0), // Remove space between tables
              Expanded(
                child: BuildUsers.buildUsersTable(context, 'Contractees', _contractees, _refreshContractees),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

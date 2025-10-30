// ignore_for_file: unused_field, deprecated_member_use

import 'dart:async';
import 'package:backend/services/superadmin%20services/superadmin_service.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:superadmin/build/builddashboard.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  Map<String, dynamic> _systemStats = {};
  Map<String, dynamic> _systemHealth = {};
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _systemAlerts = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
        _loadDashboardData(silent: true);
      }
    });
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final results = await Future.wait([
        SuperAdminServiceBackend.getSystemStatistics(),
        SuperAdminServiceBackend.getSystemHealthStatus(),
        SuperAdminServiceBackend.getDashboardData(),
        SuperAdminServiceBackend.getSystemAlerts(),
      ]);

      if (mounted) {
        setState(() {
          _systemStats = results[0] as Map<String, dynamic>; 
          _systemHealth = results[1] as Map<String, dynamic>;
          _dashboardData = results[2] as Map<String, dynamic>;
          _systemAlerts = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent) {
        await SuperAdminErrorService().logError(
          errorMessage: 'Failed to load Super Admin Dashboard data: ',
          module: 'Super Admin Dashboard',
          severity: 'Medium',
          extraInfo: {
            'operation': 'Load Dashboard Data',
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
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
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: BuildDashboard.buildDashboardLayout(
        context,
        _systemStats,
        _systemHealth,
        _systemAlerts,
        _dashboardData,
        // performanceData: _performanceMetrics, // Hidden
      ),
    );
  }
}
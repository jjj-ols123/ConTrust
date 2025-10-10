// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';

class CorDashboardService {
  final _fetchService = FetchService();

  Future<Map<String, dynamic>> loadDashboardData(String contractorId) async {
    try {
      final contractorData = await _fetchService.fetchContractorData(contractorId);
      
      final projects = await _fetchService.fetchContractorProjectInfo(contractorId);

      final completed = projects.where((p) => p['status'] == 'completed').length;
      final activeStatuses = ['active', 'awaiting_contract', 'awaiting_agreement', 'pending'];
      final active = projects.where((p) => activeStatuses.contains(p['status'])).length;
      final ratingVal = contractorData?['rating'] ?? 0.0;

      final activeProjectList = projects.where((p) => activeStatuses.contains(p['status'])).toList();
      
      for (var project in activeProjectList) {
        if (project['project_id'] != null) {
          try {
            final contracteeInfo = await _fetchService.fetchContracteeFromProject(
              project['project_id'].toString(),
            );
            if (contracteeInfo != null) {
              project['contractee_name'] = contracteeInfo['full_name'];
              project['contractee_photo'] = contracteeInfo['profile_photo'];
              project['contractee_id'] = contracteeInfo['contractee_id'];
            } else {
              project['contractee_name'] = 'Unknown Client';
              project['contractee_photo'] = null;
            }
          } catch (e) {
            project['contractee_name'] = 'Unknown Client';
            project['contractee_photo'] = null;
          }
        }
      }

      final totalEarnings = completed * 50000.0;
      final totalClients = projects.map((p) => p['contractee_id']).toSet().length;

      List<Map<String, dynamic>> localTasks = [];
      for (final project in activeProjectList) {
        final tasks = await _fetchService.fetchProjectTasks(project['project_id']);
        for (final task in tasks) {
          localTasks.add({
            ...task,
            'project_title': project['title'] ?? 'Project',
          });
        }
      }

      localTasks = localTasks.take(3).toList();

      return {
        'contractorData': contractorData,
        'activeProjects': active,
        'completedProjects': completed,
        'rating': ratingVal.toDouble(),
        'recentActivities': activeProjectList,
        'totalEarnings': totalEarnings,
        'totalClients': totalClients,
        'localTasks': localTasks,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> navigateToProject({
    required BuildContext context,
    required Map<String, dynamic> project,
    required VoidCallback onNavigate,
  }) async {
    final projectStatus = project['status']?.toString().toLowerCase();
    
    if (projectStatus != 'active') {
      if (context.mounted) {
        ConTrustSnackBar.warning(context, 
          'Project is not active yet. Current status: ${ProjectStatus().getStatusLabel(projectStatus)}');
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Project Management'),
        content: const Text('Do you want to go to Project Management Page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onNavigate();
    }
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorOngoingService {
  final _fetchService = FetchService();
  final _projectService = ProjectService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  static const String kCustomContractTypeId = 'd9d78420-7765-44d5-966c-6f0e0297c07d';

  Future<List<Map<String, dynamic>>> getContractsForProject(
    String projectId, {
    String? contractorId,
  }) async {

    if (contractorId != null) {
      final project = await _supabase
          .from('Projects')
          .select('contractor_id')
          .eq('project_id', projectId)
          .single();
      
      if (project['contractor_id'] != contractorId) {
        throw Exception('Unauthorized: You do not own this project');
      }
    }
    
    final res = await Supabase.instance.client
        .from('Contracts')
        .select('contract_id, contract_type_id, pdf_url, signed_pdf_url, contractor_signature_url, contractee_signature_url, field_values, created_at')
        .eq('project_id', projectId)
        .order('created_at', ascending: true);

    return (res as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  Future<Map<String, dynamic>?> getContractById(String contractId) async {
  try {
    final res = await _supabase
        .from('Contracts')
        .select('contract_id, contract_type_id, pdf_url, signed_pdf_url, contractor_signature_url, contractee_signature_url, field_values, created_at')
        .eq('contract_id', contractId)
        .single();

    return Map<String, dynamic>.from(res);
  } catch (e) {
    return null;
  }
}


  Future<bool> hasCustomContractForProject(
    String projectId, {
    String? contractorId,
  }) async {
    final contracts = await getContractsForProject(
      projectId,
      contractorId: contractorId,
    );
    return contracts.any((c) =>
        (c['contract_type_id']?.toString() ?? '') == kCustomContractTypeId);
  }

  Future<Map<String, dynamic>> loadProjectData(
    String projectId, {
    String? contractorId,
  }) async {
    try {
      final projectDetails = await _fetchService.fetchProjectDetails(projectId);
      
      // Validate contractor ownership
      if (contractorId != null) {
        final projectContractorId = projectDetails?['contractor_id'] as String?;
        if (projectContractorId != contractorId) {
          throw Exception('Unauthorized: You do not own this project');
        }
      }
      
      final reports = await _fetchService.fetchProjectReports(projectId);
      final photos = await _fetchService.fetchProjectPhotos(projectId);
      final costs = await _fetchService.fetchProjectCosts(projectId);
      final tasks = await _fetchService.fetchProjectTasks(projectId);
      
      final contracts = await getContractsForProject(
        projectId,
        contractorId: contractorId,
      );

      final progress = (projectDetails?['progress'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'projectDetails': projectDetails,
        'tasks': tasks,
        'reports': reports,
        'photos': photos,
        'costs': costs,
        'contracts': contracts,
        'progress': progress,
      };
    } catch (e) {
      throw Exception('Error loading project data: $e');
    }
  }

  Future<void> addReport({
    required String projectId,
    required String content,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _projectService.addReportToProject(
        projectId: projectId,
        content: content,
        authorId: userId,
      );

      if (context.mounted) {
        ConTrustSnackBar.success(
          context,
          'Report added successfully!',
        );
      }

      await _auditService.logAuditEvent(
        userId: userId,
        action: 'REPORT_ADDED',
        details: content.length > 200 ? content.substring(0, 200) : content,
        metadata: {
          'project_id': projectId,
          'author_id': userId,
        },
      );

      onSuccess();
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to add report: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {'project_id': projectId},
      );

      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error adding report: ',
        );
      }
    }
  }

  Future<void> addTask({
    required String projectId,
    required String task,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      await _projectService.addTaskToProject(
        projectId: projectId,
        task: task,
      );

      if (context.mounted) {
        ConTrustSnackBar.success(
          context,
          'Task added successfully!',
        );
      }

      await _auditService.logAuditEvent(
        userId: _supabase.auth.currentUser?.id,
        action: 'TASK_ADDED',
        details: task,
        metadata: {'project_id': projectId},
      );

      onSuccess();
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to add task: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {'project_id': projectId},
      );

      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error adding task: ',
        );
      }
    }
  }

  Future<void> uploadPhoto({
    required String projectId,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final userId = _supabase.auth.currentUser?.id;

        if (userId != null) {
          final fileName = '${projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storagePath = '$userId/$fileName';

          await _supabase.storage
              .from('projectphotos')
              .uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );

          await _projectService.addPhotoToProject(
            projectId: projectId,
            photoUrl: storagePath,
            uploaderId: userId,
          );

          if (context.mounted) {
            ConTrustSnackBar.success(
              context,
              'Photo uploaded successfully!',
            );
          }

          await _auditService.logAuditEvent(
            userId: userId,
            action: 'PROJECT_PHOTO_UPLOADED',
            details: storagePath,
            metadata: {
              'project_id': projectId,
              'uploader_id': userId,
              'path': storagePath,
            },
          );

          onSuccess();
        }
      }
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to upload photo: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {'project_id': projectId},
      );

      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error uploading photo: ',
        );
      }
    }
  }

  Future<void> updateTaskStatus({
    required String projectId,
    required String taskId,
    required bool done,
    required List<Map<String, dynamic>> allTasks,
    required BuildContext context,
    required Function(double) onProgressUpdate,
  }) async {
    try {
      await _projectService.updateTaskStatus(taskId, done);

      final updatedTasks = allTasks.map((task) {
        if (task['task_id'].toString() == taskId) {
          return {...task, 'done': done};
        }
        return task;
      }).toList();

      final completedTasks = updatedTasks.where((task) => task['done'] == true).length;
      final totalTasks = updatedTasks.length;
      final newProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

      await _supabase
          .from('Projects')
          .update({'progress': newProgress})
          .eq('project_id', projectId);

      onProgressUpdate(newProgress);

      await _auditService.logAuditEvent(
        userId: _supabase.auth.currentUser?.id,
        action: 'TASK_STATUS_UPDATED',
        details: 'Task $taskId status updated',
        metadata: {
          'project_id': projectId,
          'task_id': taskId,
          'done': done,
          'new_progress': newProgress,
        },
      );

    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to update task status: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {'project_id': projectId, 'task_id': taskId},
      );

      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error updating task status: $e',
        );
      }
      rethrow;
    }
  }


  Future<String?> createSignedPhotoUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    
    try {
      final url = await _supabase.storage
          .from('projectphotos')
          .createSignedUrl(path, 60 * 60);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteTask({
    required String taskId,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteTask(taskId);
        if (context.mounted) {
          ConTrustSnackBar.success(
            context,
            'Task deleted successfully!',
          );
        }
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context,
            'Error deleting task: ',
          );
        }
      }
    }
  }

  Future<void> deleteReport({
    required String reportId,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteReport(reportId);
        if (context.mounted) {
          ConTrustSnackBar.success(
            context,
            'Report deleted successfully!',
          );
        }
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context,
            'Error deleting report: ',
          );
        }
      }
    }
  }

  Future<void> deletePhoto({
    required String photoId,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deletePhoto(photoId);
        if (context.mounted) {
          ConTrustSnackBar.success(
            context,
            'Photo deleted successfully!',
          );
        }
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context,
            'Error deleting photo: ',
          );
        }
      }
    }
  }

  Future<void> deleteCost({
    required String materialId,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteCost(materialId);
        if (context.mounted) {
          ConTrustSnackBar.success(
            context,
            'Material deleted successfully!',
          );
        }
        onSuccess();
      } catch (e) {
        if (context.mounted) {
          ConTrustSnackBar.error(
            context,
            'Error deleting material:',
          );
        }
      }
    }
  }

  Future<void> updateEstimatedCompletion({
    required String projectId,
    required DateTime estimatedCompletion,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      final projectDetails = await _fetchService.fetchProjectDetails(projectId);
      final startDate = DateTime.parse(projectDetails?['start_date']);
      final duration = estimatedCompletion.difference(startDate).inDays;

      await _supabase
          .from('Projects')
          .update({
            'estimated_completion': estimatedCompletion.toIso8601String(),
            'duration': duration,
          })
          .eq('project_id', projectId);

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Updated successfully!');
      }
      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error updating estimated completion: ');
      }
    }
  }
}
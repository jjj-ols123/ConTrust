// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorOngoingService {
  final _fetchService = FetchService();
  final _projectService = ProjectService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> loadProjectData(String projectId) async {
    try {
      final projectDetails = await _fetchService.fetchProjectDetails(projectId);
      final reports = await _fetchService.fetchProjectReports(projectId);
      final photos = await _fetchService.fetchProjectPhotos(projectId);
      final costs = await _fetchService.fetchProjectCosts(projectId);
      final tasks = await _fetchService.fetchProjectTasks(projectId);
      final contracts = await _fetchService.fetchContractsForProject(projectId);
      
      final progress = (projectDetails?['progress'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'projectDetails': projectDetails,
        'reports': reports,
        'photos': photos,
        'costs': costs,
        'tasks': tasks,
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
      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error adding report: $e',
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
      onSuccess();
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error adding task: $e',
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
          onSuccess();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error uploading photo: $e',
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(done ? '✓ Completed' : '○ Pending'),
            backgroundColor: done ? Colors.green : Colors.orange,
            duration: const Duration(milliseconds: 600),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
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
            'Error deleting task: $e',
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
            'Error deleting report: $e',
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
            'Error deleting photo: $e',
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
            'Error deleting material: $e',
          );
        }
      }
    }
  }
}
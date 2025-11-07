// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
      
      if (projectDetails != null && projectDetails['full_name'] == null) {
        final contracteeId = projectDetails['contractee_id'] as String?;
        if (contracteeId != null) {
          try {
            final contracteeData = await _supabase
                .from('Contractee')
                .select('full_name')
                .eq('contractee_id', contracteeId)
                .maybeSingle();
            if (contracteeData != null && contracteeData['full_name'] != null) {
              projectDetails['full_name'] = contracteeData['full_name'];
            }
          } catch (_) {
            // If fetch fails, continue without full_name
          }
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

  Future<void> addReportWithPdf({
    required String projectId,
    required String title,
    required String content,
    required List<int> pdfBytes,
    required String periodType,
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload PDF to storage
      final pdfUrl = await _uploadReportPdfToStorage(
        pdfBytes: pdfBytes,
        projectId: projectId,
        contractorId: userId,
      );

      // Save report with PDF URL
      await _projectService.addReportToProject(
        projectId: projectId,
        title: title,
        content: content,
        authorId: userId,
        pdfUrl: pdfUrl,
        periodType: periodType,
      );

      if (context.mounted) {
        ConTrustSnackBar.success(
          context,
          'Report generated and saved successfully!',
        );
      }

      await _auditService.logAuditEvent(
        userId: userId,
        action: 'REPORT_ADDED_WITH_PDF',
        details: 'Progress report with PDF generated',
        metadata: {
          'project_id': projectId,
          'author_id': userId,
          'period_type': periodType,
          'pdf_url': pdfUrl,
        },
      );

      onSuccess();
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to add report with PDF: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {'project_id': projectId},
      );

      if (context.mounted) {
        ConTrustSnackBar.error(
          context,
          'Error generating report: $e',
        );
      }
    }
  }

  Future<String> _uploadReportPdfToStorage({
    required List<int> pdfBytes,
    required String projectId,
    required String contractorId,
  }) async {
    try {
      final uuid = const Uuid().v4();
      final fileName = '${projectId}_${DateTime.now().millisecondsSinceEpoch}_$uuid.pdf';
      final filePath = '$contractorId/$fileName';

      await _supabase.storage
          .from('reports')
          .uploadBinary(
            filePath,
            Uint8List.fromList(pdfBytes),
            fileOptions: const FileOptions(upsert: false),
          );

      return filePath;
    } catch (e) {
      await _errorService.logError(
        userId: contractorId,
        errorMessage: 'Failed to upload report PDF: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Upload Report PDF',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<String?> getSignedReportUrl(String pdfUrl) async {
    try {
      final response = await _supabase.storage
          .from('reports')
          .createSignedUrl(pdfUrl, 3600);
      
      if (response.isEmpty) {
        try {
          final publicUrl = _supabase.storage.from('reports').getPublicUrl(pdfUrl);
          return publicUrl;
        } catch (publicError) {
          return null;
        }
      }
      
      return response;
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to get signed report URL: $e',
        module: 'CorOngoingService',
        severity: 'Low',
        extraInfo: {'pdf_url': pdfUrl},
      );
      
      try {
        final publicUrl = _supabase.storage.from('reports').getPublicUrl(pdfUrl);
        return publicUrl;
      } catch (publicError) {
        return null;
      }
    }
  }

  Future<void> addTask({
    required String projectId,
    required String task,
    required BuildContext context,
    required VoidCallback onSuccess,
    DateTime? expectFinish,
    bool showSuccessMessage = true,
  }) async {
    try {
      await _projectService.addTaskToProject(
        projectId: projectId,
        task: task,
        expectFinish: expectFinish,
      );

      if (context.mounted && showSuccessMessage) {
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
    String? description,
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
        
        // Check file size (max 10MB)
        const maxSizeBytes = 10 * 1024 * 1024; // 10MB
        if (bytes.length > maxSizeBytes) {
          if (context.mounted) {
            ConTrustSnackBar.error(
              context, 
              'Image size exceeds 10MB limit. Please choose a smaller image.'
            );
          }
          return;
        }
        
        // Check file extension or image format (only PNG/JPG)
        final extension = pickedFile.path.contains('.') 
            ? pickedFile.path.split('.').last.toLowerCase()
            : '';
        
        // If no extension, check image format from bytes (PNG starts with 89 50 4E 47, JPEG starts with FF D8 FF)
        bool isValidImage = false;
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          isValidImage = true;
        } else if (bytes.length >= 4) {
          // Check PNG signature: 89 50 4E 47 (0x89 0x50 0x4E 0x47)
          if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
            isValidImage = true;
          }
          // Check JPEG signature: FF D8 FF
          else if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
            isValidImage = true;
          }
        }
        
        if (!isValidImage) {
          if (context.mounted) {
            ConTrustSnackBar.error(
              context, 
              'Only PNG and JPG images are allowed.'
            );
          }
          return;
        }
        
        final userId = _supabase.auth.currentUser?.id;

        if (userId != null) {
          final fileName = '${projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storagePath = 'contractor/photo_url/$fileName';

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
            description: description,
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
      
      int? duration;
      final startDateString = projectDetails?['start_date'];
      if (startDateString != null && startDateString.toString().isNotEmpty) {
        try {
          final startDate = DateTime.parse(startDateString);
          duration = estimatedCompletion.difference(startDate).inDays;
        } catch (e) {
          duration = null;
        }
      }

      final updateData = <String, dynamic>{
        'estimated_completion': estimatedCompletion.toLocal().toIso8601String(),
      };
      
      if (duration != null) {
        updateData['duration'] = duration;
      }

      await _supabase
          .from('Projects')
          .update(updateData)
          .eq('project_id', projectId);

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Updated successfully!');
      }
      onSuccess();
    } catch (e) {
      await _errorService.logError(
        userId: _supabase.auth.currentUser?.id,
        errorMessage: 'Failed to update estimated completion: $e',
        module: 'CorOngoingService',
        severity: 'Medium',
        extraInfo: {'project_id': projectId},
      );
      
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error updating estimated completion: $e');
      }
    }
  }
}
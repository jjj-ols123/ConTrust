// ignore_for_file: non_constant_identifier_names, empty_catches, no_leading_underscores_for_local_identifiers

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/superadmin services/auditlogs_service.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/both services/be_user_service.dart';

class ProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  final SuperAdminAuditService _auditService = SuperAdminAuditService();
  final SuperAdminErrorService _errorService = SuperAdminErrorService();

  //For Contractees

  Future<void> postProject({
    required String contracteeId,
    required String title,
    required String type,
    required String description,
    required String location,
    required String minBudget,
    required String maxBudget,
    required String duration,
    required DateTime startDate,
    required BuildContext context,
  }) async {
    try {
      await _userService.checkContracteeId(contracteeId);

      final existingProject = await _supabase
          .from('Projects')
          .select('project_id, status')
          .eq('contractee_id', contracteeId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingProject != null) {
        if (context.mounted) {
          ConTrustSnackBar.error(
              context, 'You cannot post a new project while a project is up.');
        }
        return;
      }

      await _supabase.from('Projects').insert({
        'contractee_id': contracteeId,
        'type': type,
        'title': title,
        'description': description,
        'location': location,
        'min_budget': minBudget,
        'max_budget': maxBudget,
        'status': 'pending',
        'duration': duration,
        'start_date': startDate.toIso8601String(),
      });

      await _auditService.logAuditEvent(
        userId: contracteeId,
        action: 'PROJECT_POSTED',
        details: 'Contractee posted a new project',
        category: 'Project',
        metadata: {
          'project_title': title,
          'project_type': type,
          'contractee_id': contracteeId,
        },
      );

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Project created successfully!');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to post project: ',
        module: 'Project Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Post Project',
          'users_id': contracteeId,
          'project_title': title,
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error creating project: ');
      }
      rethrow;
    }
  }

  Future<void> updaterojecStatus(String projectId, String status) async {
    await _supabase
        .from('Projects')
        .update({'status': status}).eq('project_id', projectId);
  }

  Future<void> deleteProject(String projectId) async {
    final _supabase = Supabase.instance.client;
    try {
      final hiringRequests = await _supabase
          .from('Notifications')
          .select('notification_id, information')
          .eq('headline', 'Hiring Request')
          .filter('information->>project_id', 'eq', projectId);
      for (final notif in hiringRequests) {
        final info = notif['information'] as Map<String, dynamic>? ?? {};
        await _supabase.from('Notifications').update({
          'information': {
            ...info,
            'status': 'deleted',
            'deleted_reason': 'Project has been deleted by the contractee',
            'deleted_at': DateTime.now().toIso8601String(),
            'delete_message': 'Project has been deleted by the contractee.'
          },
        }).eq('notification_id', notif['notification_id']);
      }
      final hiringResponses = await _supabase
          .from('Notifications')
          .select('notification_id, information')
          .eq('headline', 'Hiring Response')
          .filter('information->>project_id', 'eq', projectId);
      for (final notif in hiringResponses) {
        final info = notif['information'] as Map<String, dynamic>? ?? {};
        await _supabase.from('Notifications').update({
          'information': {
            ...info,
            'status': 'deleted',
            'deleted_reason': 'Project has been deleted by the contractee',
            'deleted_at': DateTime.now().toIso8601String(),
            'delete_message': 'Project has been deleted by the contractee.'
          },
        }).eq('notification_id', notif['notification_id']);
      }
      await _supabase.from('Projects').delete().eq('project_id', projectId);

      await _auditService.logAuditEvent(
        action: 'PROJECT_DELETED',
        details: 'Project deleted successfully',
        category: 'Project',
        metadata: {
          'project_id': projectId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete project: ',
        module: 'Project Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Delete Project',
          'project_id': projectId,
        },
      );
      throw Exception('Error updating notifications and deleting project');
    }
  }

  Future<void> notifyContractor({
    required String contractorId,
    required String contracteeId,
    required String title,
    required String type,
    required String description,
    required String location,
  }) async {
    try {
      final existingHireRequest = await FetchService()
          .hasExistingHireRequest(contractorId, contracteeId);

      if (existingHireRequest != null) {
        throw Exception(
            'You already have a pending hire request to this contractor. Please wait for their response.');
      }

      final existingProject = await _supabase
          .from('Projects')
          .select('*')
          .eq('contractee_id', contracteeId)
          .eq('title', title)
          .eq('type', type)
          .maybeSingle();

      String projectId;
      if (existingProject != null) {
        projectId = existingProject['project_id'];
      } else {
        final projectResponse = await _supabase
            .from('Projects')
            .insert({
              'contractee_id': contracteeId,
              'title': title,
              'type': type,
              'description': description,
              'location': location,
              'status': 'pending',
              'duration': 0,
            })
            .select()
            .single();
        projectId = projectResponse['project_id'];
      }

      final contracteeData =
          await FetchService().fetchContracteeData(contracteeId);
      final contracteeName = contracteeData?['full_name'] ?? 'A contractee';
      final contracteePhoto = contracteeData?['profile_photo'] ?? '';

      final contractorData =
          await FetchService().fetchContractorData(contractorId);
      final contractorName = contractorData?['firm_name'] ?? 'A contractor';

      await NotificationService().createNotification(
        receiverId: contractorId,
        receiverType: 'contractor',
        senderId: contracteeId,
        senderType: 'contractee',
        type: 'Hiring Request',
        message:
            '$contracteeName wants to hire your construction firm for: $title',
        information: {
          'contractee_id': contracteeId,
          'firm_name': contractorName,
          'contractor_id': contractorId,
          'full_name': contracteeName,
          'profile_photo': contracteePhoto,
          'project_id': projectId,
          'project_title': title,
          'project_type': type,
          'project_location': location,
          'project_description': description,
          'action': 'hire_request',
          'status': 'pending',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await _auditService.logAuditEvent(
        userId: contracteeId,
        action: 'CONTRACTOR_NOTIFIED',
        details:
            'Contractee notified contractor about project thru hire request',
        category: 'Notification',
        metadata: {
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
          'project_title': title,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to notify contractor: ',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Notify Contractor',
          'users_id': contracteeId,
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> cancelAgreement(
    String projectId,
    String requestingUserId,
  ) async {
    try {
      final project = await _supabase
          .from('Projects')
          .select('contractor_id, contractee_id')
          .eq('project_id', projectId)
          .single();

      final userType = requestingUserId == project['contractor_id']
          ? 'contractor'
          : 'contractee';

      String receiverId, receiverType, senderId, senderType, message;
      if (userType == 'contractor') {
        receiverId = project['contractee_id'];
        receiverType = 'contractee';
        senderId = project['contractor_id'];
        senderType = 'contractor';
        message = 'The contractor has requested to cancel the project';
      } else {
        receiverId = project['contractor_id'];
        receiverType = 'contractor';
        senderId = project['contractee_id'];
        senderType = 'contractee';
        message = 'The contractee has requested to cancel the project';
      }

      final status = userType == 'contractor'
          ? 'cancellation_requested_by_contractor'
          : 'cancellation_requested_by_contractee';

      await _supabase
          .from('Projects')
          .update({'status': status}).eq('project_id', projectId);

      final senderData = userType == 'contractor'
          ? await FetchService().fetchContractorData(senderId)
          : await FetchService().fetchContracteeData(senderId);
      final senderName = userType == 'contractor'
          ? (senderData != null
              ? senderData['firm_name'] ?? 'A contractor'
              : 'A contractor')
          : (senderData != null
              ? senderData['full_name'] ?? 'A contractee'
              : 'A contractee');
      final senderPhoto = senderData?['profile_photo'] ?? '';

      await NotificationService().createNotification(
        receiverId: receiverId,
        receiverType: receiverType,
        senderId: senderId,
        senderType: senderType,
        type: 'Project Cancellation Request',
        message: message,
        information: {
          'project_id': projectId,
          'action': 'cancel_request',
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
          'sender_name': senderName,
          'sender_photo': senderPhoto,
        },
      );

      await _auditService.logAuditEvent(
        userId: requestingUserId,
        action: 'AGREEMENT_CANCEL_REQUESTED',
        details: 'User requested to cancel project agreement',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'requesting_user_id': requestingUserId,
        },
      );

      return project;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to cancel agreement: ',
        module: 'Project Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Cancel Agreement',
          'users_id': requestingUserId,
          'project_id': projectId,
        },
      );
      throw Exception('Failed to cancel agreement');
    }
  }

  //For Both Users

  Future<String?> getProjectId(String chatRoomId) async {
    final chatRoom = await _supabase
        .from('ChatRoom')
        .select('project_id')
        .eq('chatroom_id', chatRoomId)
        .maybeSingle();
    return chatRoom?['project_id'];
  }

  //For Contractors

  Future<void> acceptHiring({
    required String notificationId,
    required String contractorId,
    required String contracteeId,
    required String projectId,
  }) async {
    try {
      final currentNotification = await _supabase
          .from('Notifications')
          .select('information')
          .eq('notification_id', notificationId)
          .single();

      await _supabase.from('Projects').update({
        'contractor_id': contractorId,
        'status': 'awaiting_contract',
      }).eq('project_id', projectId);

      final currentInfo =
          Map<String, dynamic>.from(currentNotification['information'] ?? {});
      currentInfo['status'] = 'accepted';
      currentInfo['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('Notifications').update({
        'information': {
          ...currentInfo,
          'status': 'accepted',
        }
      }).eq('notification_id', notificationId);

      await cancelOtherHireRequests(projectId, contracteeId, notificationId);

      final contractorData =
          await FetchService().fetchContractorData(contractorId);
      final contractorName = contractorData?['firm_name'] ?? 'A contractor';
      final contactorPhoto = contractorData?['profile_photo'] ?? '';

      await NotificationService().createNotification(
        receiverId: contracteeId,
        receiverType: 'contractee',
        senderId: contractorId,
        senderType: 'contractor',
        type: 'Hiring Response',
        message: 'Your hiring request has been accepted!',
        information: {
          'contractor_id': contractorId,
          'contractor_name': contractorName,
          'contractor_photo': contactorPhoto,
          'action': 'hire_accepted',
          'original_notification_id': notificationId,
          'timestamp': DateTime.now().toIso8601String(),
          'sender_name': contractorName,
          'sender_photo': contactorPhoto,
        },
      );

      await _auditService.logAuditEvent(
        userId: contractorId,
        action: 'HIRING_ACCEPTED',
        details: 'Contractor accepted hiring request',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to accept hiring: ',
        module: 'Project Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Accept Hiring',
          'users_id': contractorId,
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<void> cancelOtherHireRequests(String projectId, String contracteeId,
      String acceptedNotificationId) async {
    try {
      final otherRequests = await _supabase
          .from('Notifications')
          .select('notification_id, information')
          .eq('headline', 'Hiring Request')
          .eq('sender_id', contracteeId)
          .filter('information->>project_id', 'eq', projectId)
          .neq('notification_id', acceptedNotificationId);

      for (final request in otherRequests) {
        final info = Map<String, dynamic>.from(request['information'] ?? {});
        info['status'] = 'cancelled';
        info['cancelled_reason'] = 'Another contractor was selected';
        info['cancelled_at'] = DateTime.now().toIso8601String();

        await _supabase.from('Notifications').update({
          'information': info,
        }).eq('notification_id', request['notification_id']);

        await _auditService.logAuditEvent(
          userId: contracteeId,
          action: 'HIRE_REQUEST_CANCELLED',
          details: 'Hire request cancelled due to another contractor selected',
          category: 'Notification',
          metadata: {
            'notification_id': request['notification_id'],
            'project_id': projectId,
          },
        );
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to cancel other hire requests: ',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Cancel Other Hire Requests',
          'users_id': contracteeId,
          'project_id': projectId,
        },
      );
      return;
    }
  }

  Future<void> declineHiring({
    required String notificationId,
    required String contractorId,
    required String contracteeId,
  }) async {
    try {
      final currentNotification = await _supabase
          .from('Notifications')
          .select('information')
          .eq('notification_id', notificationId)
          .single();

      final currentInfo =
          Map<String, dynamic>.from(currentNotification['information'] ?? {});
      currentInfo['status'] = 'declined';
      currentInfo['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('Notifications').update({
        'information': currentInfo,
      }).eq('notification_id', notificationId);

      final contractorData =
          await FetchService().fetchContractorData(contractorId);
      final contractorName = contractorData?['firm_name'] ?? 'A contractor';
      final contractorPhoto = contractorData?['profile_photo'] ?? '';

      await NotificationService().createNotification(
        receiverId: contracteeId,
        receiverType: 'contractee',
        senderId: contractorId,
        senderType: 'contractor',
        type: 'Hiring Response',
        message: 'Your hiring request has been declined.',
        information: {
          'contractor_id': contractorId,
          'contractor_name': contractorName,
          'contractor_photo': contractorPhoto,
          'action': 'hire_declined',
          'original_notification_id': notificationId,
          'timestamp': DateTime.now().toIso8601String(),
          'sender_name': contractorName,
          'sender_photo': contractorPhoto,
        },
      );

      await _auditService.logAuditEvent(
        userId: contractorId,
        action: 'HIRING_DECLINED',
        details: 'Contractor declined hiring request',
        category: 'Project',
        metadata: {
          'contractor_id': contractorId,
          'contractee_id': contracteeId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to decline hiring: ',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Decline Hiring',
          'users_id': contractorId,
        },
      );
      throw Exception('Failed to decline hiring request');
    }
  }

  Future<Map<String, dynamic>?> agreeCancelAgreement(
      String projectId, String agreeingUserId) async {
    try {
      final project = await _supabase
          .from('Projects')
          .select('contractor_id, contractee_id')
          .eq('project_id', projectId)
          .single();

      final contractorId = project['contractor_id'];
      final contracteeId = project['contractee_id'];

      String receiverId, receiverType, senderId, senderType;
      if (agreeingUserId == contractorId) {
        senderId = contractorId;
        senderType = 'contractor';
        receiverId = contracteeId;
        receiverType = 'contractee';
      } else {
        senderId = contracteeId;
        senderType = 'contractee';
        receiverId = contractorId;
        receiverType = 'contractor';
      }

      await _supabase.from('Projects').update({
        'status': 'cancelled',
        'contractor_id': null,
      }).eq('project_id', projectId);

      final senderData = senderType == 'contractor'
          ? await FetchService().fetchContractorData(senderId)
          : await FetchService().fetchContracteeData(senderId);
      final senderName = senderType == 'contractor'
          ? (senderData != null
              ? senderData['firm_name'] ?? 'A contractor'
              : 'A contractor')
          : (senderData != null
              ? senderData['full_name'] ?? 'A contractee'
              : 'A contractee');
      final senderPhoto = senderData?['profile_photo'] ?? '';

      await NotificationService().createNotification(
        receiverId: receiverId,
        receiverType: receiverType,
        senderId: senderId,
        senderType: senderType,
        type: 'Project Cancellation Response',
        message: 'The $senderType has agreed to cancel the project.',
        information: {
          'project_id': projectId,
          'action': 'cancel_agreed',
          'status': 'cancelled',
          'timestamp': DateTime.now().toIso8601String(),
          'sender_name': senderName,
          'sender_photo': senderPhoto,
        },
      );

      await _auditService.logAuditEvent(
        userId: agreeingUserId,
        action: 'AGREEMENT_CANCEL_AGREED',
        details: 'User agreed to cancel project agreement',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'agreeing_user_id': agreeingUserId,
        },
      );

      return project;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to agree to cancel agreement: ',
        module: 'Project Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Agree Cancel Agreement',
          'users_id': agreeingUserId,
          'project_id': projectId,
        },
      );
      throw Exception('Failed to agree to cancellation');
    }
  }

  Future<Map<String, dynamic>?> declineCancelAgreement(
    String projectId,
    String decliningUserId,
  ) async {
    try {
      final project = await _supabase
          .from('Projects')
          .select('contractor_id, contractee_id')
          .eq('project_id', projectId)
          .single();

      final userType = decliningUserId == project['contractor_id']
          ? 'contractor'
          : 'contractee';
      final notifInfo = await FetchService().userTypeDecide(
        contractId: projectId,
        userType: userType,
        action: 'declined the cancellation request',
      );

      await _supabase
          .from('Projects')
          .update({'status': 'awaiting_contract'}).eq('project_id', projectId);

      final senderData = userType == 'contractor'
          ? await FetchService().fetchContractorData(decliningUserId)
          : await FetchService().fetchContracteeData(decliningUserId);
      final senderName = userType == 'contractor'
          ? (senderData != null ? senderData['firm_name'] : 'A contractor')
          : senderData?['full_name'] ?? 'A contractee';
      final senderPhoto = senderData?['profile_photo'] ?? '';

      await NotificationService().createNotification(
        receiverId: notifInfo['receiverId'] ?? '',
        receiverType: notifInfo['receiverType'] ?? '',
        senderId: notifInfo['senderId'] ?? '',
        senderType: notifInfo['senderType'] ?? '',
        type: 'Project Cancellation Response',
        message: notifInfo['message'] ?? '',
        information: {
          'project_id': projectId,
          'action': 'cancel_declined',
          'status': 'active',
          'timestamp': DateTime.now().toIso8601String(),
          'sender_name': senderName,
          'sender_photo': senderPhoto,
        },
      );

      await _auditService.logAuditEvent(
        userId: decliningUserId,
        action: 'AGREEMENT_CANCEL_DECLINED',
        details: 'User declined to cancel project agreement',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'declining_user_id': decliningUserId,
        },
      );

      return project;
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to decline cancel agreement: ',
        module: 'Project Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Decline Cancel Agreement',
          'users_id': decliningUserId,
          'project_id': projectId,
        },
      );
      throw Exception('Failed to decline cancellation');
    }
  }

  Future<void> addTaskToProject({
    required String projectId,
    required String task,
    bool done = false,
  }) async {
    try {
      await _supabase.from('ProjectTasks').insert({
        'project_id': projectId,
        'task': task,
        'done': done,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _auditService.logAuditEvent(
        action: 'TASK_ADDED',
        details: 'Task added to project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'task': task,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to add task to project: ',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Add Task to Project',
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<void> addReportToProject({
    required String projectId,
    required String content,
    required String authorId,
  }) async {
    try {
      await _supabase.from('ProjectReports').insert({
        'project_id': projectId,
        'content': content,
        'author_id': authorId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _auditService.logAuditEvent(
        userId: authorId,
        action: 'REPORT_ADDED',
        details: 'Report added to project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'author_id': authorId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to add report to project:',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Add Report to Project',
          'users_id': authorId,
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<void> addPhotoToProject({
    required String projectId,
    required String photoUrl,
    required String uploaderId,
  }) async {
    try {
      await _supabase.from('ProjectPhotos').insert({
        'project_id': projectId,
        'photo_url': photoUrl,
        'uploader_id': uploaderId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _auditService.logAuditEvent(
        userId: uploaderId,
        action: 'PHOTO_ADDED',
        details: 'Photo added to project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'uploader_id': uploaderId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to add photo to project: ',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Add Photo to Project',
          'users_id': uploaderId,
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<void> addCostToProject({
    required String contractor_id,
    required String projectId,
    required String material_name,
    required num quantity,
    String? brand,
    String? unit,
    num? unit_price,
    String? notes,
  }) async {
    try {
      await _supabase.from('ProjectMaterials').insert({
        'contractor_id': contractor_id,
        'project_id': projectId,
        'material_name': material_name,
        'brand': brand,
        'unit': unit,
        'quantity': quantity,
        'unit_price': unit_price,
        if (notes != null) 'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _auditService.logAuditEvent(
        userId: contractor_id,
        action: 'COST_ADDED',
        details: 'Cost/material added to project',
        category: 'Project',
        metadata: {
          'project_id': projectId,
          'contractor_id': contractor_id,
          'material_name': material_name,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to add cost to project: ',
        module: 'Project Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Add Cost to Project',
          'users_id': contractor_id,
          'project_id': projectId,
        },
      );
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, bool done) async {
    try {
      await _supabase
          .from('ProjectTasks')
          .update({'done': done}).eq('task_id', taskId);

      await _auditService.logAuditEvent(
        action: 'TASK_STATUS_UPDATED',
        details: 'Task status updated',
        category: 'Project',
        metadata: {
          'task_id': taskId,
          'done': done,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to update task status: ',
        module: 'Project Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Update Task Status',
          'task_id': taskId,
        },
      );
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('ProjectTasks').delete().eq('task_id', taskId);

      await _auditService.logAuditEvent(
        action: 'TASK_DELETED',
        details: 'Task deleted from project',
        category: 'Project',
        metadata: {
          'task_id': taskId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete task: $e',
        module: 'Project Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Delete Task',
          'task_id': taskId,
        },
      );
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _supabase.from('ProjectReports').delete().eq('report_id', reportId);

      await _auditService.logAuditEvent(
        action: 'REPORT_DELETED',
        details: 'Report deleted from project',
        category: 'Project',
        metadata: {
          'report_id': reportId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete report: ',
        module: 'Project Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Delete Report',
          'report_id': reportId,
        },
      );
      rethrow;
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      final photo = await _supabase
          .from('ProjectPhotos')
          .select('photo_url')
          .eq('photo_id', photoId)
          .single();

      final photoUrl = photo['photo_url'] as String?;

      await _supabase.from('ProjectPhotos').delete().eq('photo_id', photoId);

      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          await _supabase.storage.from('projectphotos').remove([photoUrl]);
        } catch (e) {}
      }

      await _auditService.logAuditEvent(
        action: 'PHOTO_DELETED',
        details: 'Photo deleted from project',
        category: 'Project',
        metadata: {
          'photo_id': photoId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete photo: ',
        module: 'Project Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Delete Photo',
          'photo_id': photoId,
        },
      );
      rethrow;
    }
  }

  Future<void> deleteCost(String materialId) async {
    try {
      await _supabase
          .from('ProjectMaterials')
          .delete()
          .eq('material_id', materialId);

      await _auditService.logAuditEvent(
        action: 'COST_DELETED',
        details: 'Cost/material deleted from project',
        category: 'Project',
        metadata: {
          'material_id': materialId,
        },
      );
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to delete cost: ',
        module: 'Project Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Delete Cost',
          'material_id': materialId,
        },
      );
      rethrow;
    }
  }
}

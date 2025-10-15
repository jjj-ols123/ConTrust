// ignore_for_file: non_constant_identifier_names, empty_catches, no_leading_underscores_for_local_identifiers

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/both services/be_user_service.dart';

class ProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

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
          ConTrustSnackBar.error(context, 'You cannot post a new project while a project is up.');
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

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Project created successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error creating project: $e');
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
    } catch (e) {
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
      final existingHireRequest =
          await FetchService().hasExistingHireRequest(contractorId, contracteeId);

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
    } catch (e) {
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
        },
      );

      return project;
    } catch (e) {
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
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOtherHireRequests(
      String projectId, String contracteeId, String acceptedNotificationId) async {
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
      }
    } catch (e) {
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
        },
      );
    } catch (e) {
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
        },
      );

      return project;
    } catch (e) {
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
        },
      );

      return project;
    } catch (e) {
      throw Exception('Failed to decline cancellation');
    }
  }

  Future<void> addTaskToProject({
    required String projectId,
    required String task,
    bool done = false,
  }) async {
    await _supabase.from('ProjectTasks').insert({
      'project_id': projectId,
      'task': task,
      'done': done,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addReportToProject({
    required String projectId,
    required String content,
    required String authorId,
  }) async {
    await _supabase.from('ProjectReports').insert({
      'project_id': projectId,
      'content': content,
      'author_id': authorId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addPhotoToProject({
    required String projectId,
    required String photoUrl,
    required String uploaderId,
  }) async {
    await _supabase.from('ProjectPhotos').insert({
      'project_id': projectId,
      'photo_url': photoUrl,
      'uploader_id': uploaderId,
      'created_at': DateTime.now().toIso8601String(),
    });
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
  }

  Future<void> updateTaskStatus(String taskId, bool done) async {
    await _supabase
        .from('ProjectTasks')
        .update({'done': done})
        .eq('task_id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase
        .from('ProjectTasks')
        .delete()
        .eq('task_id', taskId);
  }

  Future<void> deleteReport(String reportId) async {
    await _supabase
        .from('ProjectReports')
        .delete()
        .eq('report_id', reportId);
  }

  Future<void> deletePhoto(String photoId) async {
    final photo = await _supabase
        .from('ProjectPhotos')
        .select('photo_url')
        .eq('photo_id', photoId)
        .single();
    
    final photoUrl = photo['photo_url'] as String?;
    
    await _supabase
        .from('ProjectPhotos')
        .delete()
        .eq('photo_id', photoId);
    
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        await _supabase.storage
            .from('projectphotos')
            .remove([photoUrl]);
      } catch (e) {
      }
    }
  }

  Future<void> deleteCost(String materialId) async {
    await _supabase
        .from('ProjectMaterials')
        .delete()
        .eq('material_id', materialId);
  }
}

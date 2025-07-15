import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/services/be_notification_service.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/be_user_service.dart';

class ProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

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

      await _supabase.from('Projects').upsert({
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
      }, onConflict: 'contractee_id');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e is PostgrestException &&
            e.code == '23505' &&
            e.message.contains('unique_contractee_id')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only post one project')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inserting data')),
          );
        }
      }
      rethrow;
    }
  }

  Future<void> updateProjectStatus(String projectId, String status) async {
    await _supabase
        .from('Projects')
        .update({'status': status}).eq('project_id', projectId);
  }

  Future<void> deleteProject(String projectId) async {
    await _supabase.from('Projects').delete().eq('project_id', projectId);
  }

  Future<Map<String, dynamic>?> getProjectDetails(String projectId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('*')
          .eq('project_id', projectId)
          .single();
      return response;
    } catch (error) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsByContractee(
      String contracteeId) async {
    try {
      final response = await _supabase
          .from('Projects')
          .select('*')
          .eq('contractee_id', contracteeId);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      return [];
    }
  }

  Future<String?> getProjectId(String chatRoomId) async {
    final chatRoom = await _supabase
        .from('ChatRoom')
        .select('project_id')
        .eq('chatroom_id', chatRoomId)
        .maybeSingle();
    return chatRoom?['project_id'];
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
          await hasExistingHireRequest(contractorId, contracteeId);

      if (existingHireRequest != null) {
        throw Exception(
            'You already have a pending hire request to this contractor. Please wait for their response.');
      }

      final existingProject = await hasExistingProject(contracteeId);

      String projectId;

      if (existingProject != null &&
          existingProject['title'] == title &&
          existingProject['type'] == type) {
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
            })
            .select()
            .single();
        projectId = projectResponse['project_id'];
      }

      final contracteeData =
          await FetchService().fetchContracteeData(contracteeId);
      final contracteeName = contracteeData?['full_name'] ?? 'A contractee';

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
          'full_name': contracteeName,
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

      await _supabase
          .from('Notifications')
          .update({
            'information': {
              ...currentInfo,
              'status': 'accepted',
            }
          })
          .eq('notification_id', notificationId);

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

}

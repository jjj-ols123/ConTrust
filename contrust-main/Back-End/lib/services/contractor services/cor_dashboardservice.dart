// ignore_for_file: use_build_context_synchronously

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/services/superadmin services/errorlogs_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class CorDashboardService {
  final _fetchService = FetchService();
  static final SuperAdminErrorService _errorService = SuperAdminErrorService();

  Future<Map<String, dynamic>> loadDashboardData(String contractorId) async {
    try {
      final contractorData = await _fetchService.fetchContractorData(contractorId);
      
      final projects = await _fetchService.fetchContractorProjectInfo(contractorId);

      final completed = projects.where((p) => p['status'] == 'completed').length;
      final activeStatuses = ['active', 'awaiting_contract', 'awaiting_agreement', 'pending', 'awaiting_signature', 'cancellation_requested_by_contractee'];
      final active = projects.where((p) => activeStatuses.contains(p['status'])).length;
      final ratingVal = contractorData?['rating'] ?? 0.0;

      final activeProjectList = projects.where((p) => activeStatuses.contains(p['status'])).toList();
      
      final contracteeIds = activeProjectList
          .map((p) => p['contractee_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();
      
      final Map<String, Map<String, dynamic>> contracteeInfoMap = {};
      if (contracteeIds.isNotEmpty) {
        try {
          final contracteeData = await Supabase.instance.client
              .from('Contractee')
              .select('contractee_id, full_name, profile_photo')
              .inFilter('contractee_id', contracteeIds);
          
          for (var contractee in contracteeData) {
            contracteeInfoMap[contractee['contractee_id']] = {
              'full_name': contractee['full_name'] ?? 'Unknown Client',
              'profile_photo': contractee['profile_photo'],
              'contractee_id': contractee['contractee_id'],
            };
          }
        } catch (e) {
          // Error fetching contractee data - will use defaults
        }
      }
      
      // Batch fetch cancellation notifications for all cancellation requests
      final cancellationProjectIds = activeProjectList
          .where((p) => p['status'] == 'cancellation_requested_by_contractee')
          .map((p) => p['project_id'].toString())
          .toList();
      
      final Map<String, Map<String, dynamic>> cancellationInfoMap = {};
      if (cancellationProjectIds.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          final notifications = await supabase
              .from('Notifications')
              .select('information')
              .eq('headline', 'Project Cancellation Request')
              .eq('receiver_id', contractorId)
              .order('created_at', ascending: false);
          
          for (var notif in notifications) {
            final info = notif['information'] as Map<String, dynamic>? ?? {};
            final projectId = info['project_id']?.toString();
            if (projectId != null && cancellationProjectIds.contains(projectId)) {
              cancellationInfoMap[projectId] = {
                'cancellation_reason': info['cancellation_reason'] ?? 'No reason provided',
                'message': info['message'] ?? '',
                'requested_at': info['requested_at'] ?? '',
              };
            }
          }
        } catch (e) {
          // Error fetching notifications - will use defaults
        }
      }
      
      // Populate project data with batch-fetched contractee info
      for (var project in activeProjectList) {
        final contracteeId = project['contractee_id'] as String?;
        if (contracteeId != null && contracteeInfoMap.containsKey(contracteeId)) {
          final contracteeInfo = contracteeInfoMap[contracteeId]!;
          project['contractee_name'] = contracteeInfo['full_name'];
          project['contractee_photo'] = contracteeInfo['profile_photo'];
          project['contractee_id'] = contracteeInfo['contractee_id'];
        } else {
          project['contractee_name'] = 'Unknown Client';
          project['contractee_photo'] = null;
        }
        
        if (project['status'] == 'cancellation_requested_by_contractee') {
          final projectId = project['project_id'].toString();
          if (cancellationInfoMap.containsKey(projectId)) {
            project['information'] = cancellationInfoMap[projectId];
          } else {
            project['information'] = {
              'cancellation_reason': 'No reason provided',
              'message': 'The contractee has requested to cancel this project.',
            };
          }
        }
      }

      final totalEarnings = completed * 50000.0;
      final totalClients = projects.map((p) => p['contractee_id']).toSet().length;

      // Batch fetch tasks for all active projects
      List<Map<String, dynamic>> localTasks = [];
      if (activeProjectList.isNotEmpty) {
        final projectIds = activeProjectList
            .map((p) => p['project_id'].toString())
            .toList();
        
        try {
          final allTasks = await Supabase.instance.client
              .from('ProjectTasks')
              .select('task_id, project_id, task_name, status, created_at, completed_at')
              .inFilter('project_id', projectIds)
              .order('created_at', ascending: false);
          
          final Map<String, List<Map<String, dynamic>>> tasksByProject = {};
          for (var task in allTasks) {
            final projId = task['project_id'].toString();
            if (!tasksByProject.containsKey(projId)) {
              tasksByProject[projId] = [];
            }
            tasksByProject[projId]!.add(task);
          }
          
          for (final project in activeProjectList) {
            final projectId = project['project_id'].toString();
            final projectTasks = tasksByProject[projectId] ?? [];
            for (final task in projectTasks) {
              localTasks.add({
                ...task,
                'project_title': project['title'] ?? 'Project',
              });
            }
          }
        } catch (e) {
          // Error fetching tasks - localTasks remains empty
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
      await _errorService.logError(
        errorMessage: 'Failed to load dashboard data: $e',
        module: 'Contractor Dashboard Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Load Dashboard Data',
          'contractor_id': contractorId,
        },
      );
      rethrow;
    }
  }

  Future<void> navigateToProject({
    required BuildContext context,
    required Map<String, dynamic> project,
    required VoidCallback onNavigate,
  }) async {
    try {
      final projectStatus = project['status']?.toString().toLowerCase();
      
      final allowedStatuses = ['active'];
      if (!allowedStatuses.contains(projectStatus)) {
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
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to navigate to project: $e',
        module: 'Contractor Dashboard Service',
        severity: 'Low',
        extraInfo: {
          'operation': 'Navigate to Project',
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingHiringRequests() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final notifications = await Supabase.instance.client
          .from('Notifications')
          .select('''
            notification_id, 
            information, 
            created_at,
            sender_id
          ''')
          .eq('headline', 'Hiring Request')
          .eq('receiver_id', currentUserId)
          .inFilter('information->>status', ['pending', 'accepted', 'rejected', 'declined', 'cancelled'])
          .order('created_at', ascending: false);

      final senderIds = notifications
          .map((n) => n['sender_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      
      final Map<String, String> emailMap = {};
      if (senderIds.isNotEmpty) {
        try {
          final users = await Supabase.instance.client
              .from('Users')
              .select('users_id, email')
              .inFilter('users_id', senderIds);
          
          for (var user in users) {
            emailMap[user['users_id']] = user['email'] ?? '';
          }
        } catch (e) {
          await _errorService.logError(
            errorMessage: 'Error batch fetching user emails: $e',
            module: 'Contractor Dashboard Service',
            severity: 'Low',
            extraInfo: {
              'operation': 'Batch Fetch User Emails',
              'sender_ids': senderIds,
            },
          );
        }
      }
      
      for (var notification in notifications) {
        final senderId = notification['sender_id'] as String?;
        if (senderId != null && emailMap.containsKey(senderId)) {
          final info = Map<String, dynamic>.from(notification['information'] ?? {});
          info['email'] = emailMap[senderId];
          notification['information'] = info;
        }
      }

      // Sort: accepted first, then pending, then rejected/declined (by created_at descending within groups)
      notifications.sort((a, b) {
        String sa = (a['information']?['status'] ?? 'pending').toString().toLowerCase();
        String sb = (b['information']?['status'] ?? 'pending').toString().toLowerCase();
        int rank(String s) {
          switch (s) {
            case 'accepted':
              return 0;
            case 'pending':
              return 1;
            case 'rejected':
            case 'declined':
            case 'cancelled':
              return 2;
            default:
              return 3;
          }
        }
        final r = rank(sa).compareTo(rank(sb));
        if (r != 0) return r;
        final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      return List<Map<String, dynamic>>.from(notifications);
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to fetch pending hiring requests: $e',
        module: 'Contractor Dashboard Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Pending Hiring Requests',
        },
      );
      return [];
    }
  }

  Future<void> handleAcceptHiring({
    required BuildContext context,
    required String notificationId,
    required Map<String, dynamic> info,
  }) async {
    try {
      final currentNotification = await Supabase.instance.client
          .from('Notifications')
          .select('information')
          .eq('notification_id', notificationId)
          .single();

      final currentInfo = Map<String, dynamic>.from(currentNotification['information'] ?? {});
      currentInfo['status'] = 'accepted';
      
      await Supabase.instance.client
          .from('Notifications')
          .update({
            'information': currentInfo,
          })
          .eq('notification_id', notificationId);

      final projectId = currentInfo['project_id'];
      if (projectId != null) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final contractorId = currentUser.id;
          
          await Supabase.instance.client
              .from('Projects')
              .update({
                'status': 'awaiting_contract',
                'contractor_id': contractorId, 
              })
              .eq('project_id', projectId);

          // Get contractee ID from the project
          final projectData = await Supabase.instance.client
              .from('Projects')
              .select('contractee_id')
              .eq('project_id', projectId)
              .single();
          
          final contracteeId = projectData['contractee_id'] as String?;
          
          if (contracteeId != null) {
            // Cancel other hiring requests for this project
            await _cancelOtherHireRequests(projectId, contracteeId, notificationId);
            
            // Create or get chat room for communication
            try {
              final messageService = MessageService();
              await messageService.getOrCreateChatRoom(
                contractorId: contractorId,
                contracteeId: contracteeId,
                projectId: projectId,
              );
            } catch (e) {
              // Log error but don't fail the entire operation
              await _errorService.logError(
                errorMessage: 'Failed to create chat room after accepting hiring: $e',
                module: 'Contractor Dashboard Service',
                severity: 'Medium',
                extraInfo: {
                  'operation': 'Accept Hiring - Create Chat Room',
                  'project_id': projectId,
                  'contractor_id': contractorId,
                  'contractee_id': contracteeId,
                },
              );
            }

            // Send notification to contractee about acceptance
            try {
              final contractorData = await _fetchService.fetchContractorData(contractorId);
              final contractorName = contractorData?['firm_name'] ?? 'A contractor';
              final contractorPhoto = contractorData?['profile_photo'] ?? '';

              await NotificationService().createNotification(
                receiverId: contracteeId,
                receiverType: 'contractee',
                senderId: contractorId,
                senderType: 'contractor',
                type: 'Hiring Response',
                message: 'Congratulations! Your hiring request has been accepted by $contractorName. Please proceed to Messages to discuss further details.',
                information: {
                  'contractor_id': contractorId,
                  'contractor_name': contractorName,
                  'contractor_photo': contractorPhoto,
                  'action': 'hire_accepted',
                  'original_notification_id': notificationId,
                  'project_id': projectId,
                },
              );
            } catch (e) {
              // Log error but don't fail the entire operation
              await _errorService.logError(
                errorMessage: 'Failed to send notification after accepting hiring: $e',
                module: 'Contractor Dashboard Service',
                severity: 'Medium',
                extraInfo: {
                  'operation': 'Accept Hiring - Send Notification',
                  'project_id': projectId,
                  'contractor_id': contractorId,
                  'contractee_id': contracteeId,
                },
              );
            }
          }
        }
      }

      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Hiring request accepted successfully! Proceed to message for further discussion with the contractee.');
        context.go('/dashboard');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Error accepting hiring request: $e',
        module: 'Contractor Dashboard Service',
        severity: 'High',
        extraInfo: {
          'operation': 'Accept Hiring Request',
          'notification_id': notificationId,
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error accepting hiring request: $e');
      }
    }
  }

  Future<void> handleDeclineHiring({
    required BuildContext context,
    required String notificationId,
  }) async {
    try {
      // Get current notification to preserve existing information
      final currentNotification = await Supabase.instance.client
          .from('Notifications')
          .select('information')
          .eq('notification_id', notificationId)
          .single();
      
      // Update the status within the information object
      final currentInfo = Map<String, dynamic>.from(currentNotification['information'] ?? {});
      currentInfo['status'] = 'declined';
      
      // Update notification information status to declined
      await Supabase.instance.client
          .from('Notifications')
          .update({
            'information': currentInfo,
          })
          .eq('notification_id', notificationId);


      if (context.mounted) {
        ConTrustSnackBar.success(context, 'Hiring request declined.');
        context.go('/dashboard');
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Error declining hiring request: $e',
        module: 'Contractor Dashboard Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Decline Hiring Request',
          'notification_id': notificationId,
        },
      );
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error declining hiring request: $e');
      }
    }
  }

  Future<void> _cancelOtherHireRequests(String projectId, String contracteeId, String acceptedNotificationId) async {
    try {
      final otherRequests = await Supabase.instance.client
          .from('Notifications')
          .select('notification_id, information')
          .eq('headline', 'Hiring Request')
          .eq('sender_id', contracteeId)
          .filter('information->>project_id', 'eq', projectId)
          .neq('notification_id', acceptedNotificationId);

      for (final request in otherRequests) {
        final info = Map<String, dynamic>.from(request['information'] ?? {});
        // Set other requests as rejected so they remain visible to both parties
        info['status'] = 'rejected';
        // Clean up any previously used cancelled fields if present
        info.remove('cancelled_reason');
        info.remove('cancelled_at');

        await Supabase.instance.client.from('Notifications').update({
          'information': info,
        }).eq('notification_id', request['notification_id']);
      }
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to cancel other hiring requests: $e',
        module: 'Contractor Dashboard Service',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Cancel Other Hiring Requests',
          'project_id': projectId,
          'accepted_notification_id': acceptedNotificationId,
        },
      );
    }
  }
}

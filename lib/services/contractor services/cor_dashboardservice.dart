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
      final activeStatuses = ['active', 'awaiting_contract', 'awaiting_agreement', 'pending', 'cancellation_requested_by_contractee'];
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
          
          // Fetch cancellation information if project has cancellation request status
          if (project['status'] == 'cancellation_requested_by_contractee') {
            try {
              final supabase = Supabase.instance.client;
              final cancellationNotification = await supabase
                  .from('Notifications')
                  .select('information')
                  .eq('headline', 'Project Cancellation Request')
                  .filter('information->>project_id', 'eq', project['project_id'].toString())
                  .eq('receiver_id', contractorId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();

              if (cancellationNotification != null) {
                final info = cancellationNotification['information'] as Map<String, dynamic>? ?? {};
                project['information'] = {
                  'cancellation_reason': info['cancellation_reason'] ?? 'No reason provided',
                  'message': info['message'] ?? '',
                  'requested_at': info['requested_at'] ?? '',
                };
              }
            } catch (e) {
              // If fetching cancellation info fails, provide default
              project['information'] = {
                'cancellation_reason': 'No reason provided',
                'message': 'The contractee has requested to cancel this project.',
              };
            }
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
      await _errorService.logError(
        errorMessage: 'Failed to load dashboard data: ',
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
    } catch (e) {
      await _errorService.logError(
        errorMessage: 'Failed to navigate to project: ',
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
          .filter('information->>status', 'eq', 'pending')
          .order('created_at', ascending: false);

      // Fetch user emails for each notification
      for (var notification in notifications) {
        final senderId = notification['sender_id'];
        if (senderId != null) {
          try {
            final userResponse = await Supabase.instance.client
                .from('Users')
                .select('email')
                .eq('id', senderId)
                .single();
            
            // Add email to the information object
            final info = Map<String, dynamic>.from(notification['information'] ?? {});
            info['email'] = userResponse['email'];
            notification['information'] = info;
          } catch (e) {
            // If user not found, keep existing info without email
            await _errorService.logError(
              errorMessage: 'Error fetching user email: $e',
              module: 'Contractor Dashboard Service',
              severity: 'Low',
              extraInfo: {
                'operation': 'Fetch User Email',
                'sender_id': senderId,
              },
            );
          }
        }
      }

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

      // When hiring request is declined, keep project status as 'pending' 
      // so contractee can hire other contractors
      final projectId = currentInfo['project_id'];
      if (projectId != null) {
        await Supabase.instance.client
            .from('Projects')
            .update({
              'status': 'pending',
            })
            .eq('project_id', projectId);
      }

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
        info['status'] = 'cancelled';
        info['cancelled_reason'] = 'Another contractor was selected';
        info['cancelled_at'] = DateTime.now().toIso8601String();

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

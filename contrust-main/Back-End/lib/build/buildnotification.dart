// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:backend/services/both%20services/be_notification_service.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shared helper to format timestamps as relative time
String formatTimeAgo(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) return '';
  try {
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

String formatLocalTime(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) return '';
  try {
    final dt = DateTime.parse(timestamp).toLocal();
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  } catch (_) {
    return formatTimeAgo(timestamp);
  }
}

class NotificationUIBuildMethods {
  NotificationUIBuildMethods({
    required this.context,
    required this.receiverId,
  });

  final BuildContext context;
  final String receiverId;

  double get screenWidth => MediaQuery.of(context).size.width;
  bool get isDesktop => screenWidth > 1200;

  /// Get date string from timestamp (YYYY-MM-DD)
  String _getDateString(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// Get date label (today, yesterday, or formatted date)
  String _getDateLabel(String dateStr) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (dateStr == todayStr) return 'today';
    
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    
    if (dateStr == yesterdayStr) return 'yesterday';
    
    try {
      final dt = DateTime.parse('$dateStr 00:00:00');
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications(
      List<Map<String, dynamic>> notifications) {
    // Use composite keys: 'type_date' (e.g., 'hiring_requests_2024-01-15')
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final List<Map<String, dynamic>> otherNotifications = [];

    for (var notification in notifications) {
      final createdAt = notification['created_at'] as String?;
      final headline = notification['headline'] as String?;
      String? dateStr;
      String? groupType;

      if (headline == 'Hiring Request') {
        final rawInfo = notification['information'];
        final info = rawInfo is String
            ? Map<String, dynamic>.from(jsonDecode(rawInfo))
            : Map<String, dynamic>.from(rawInfo ?? {});
        final status = info['status'] as String?;
        final updatedAt = info['updated_at'] as String?;

        if (status == 'pending' && createdAt != null) {
          dateStr = _getDateString(createdAt);
          groupType = 'hiring_requests';
        } else if (status == 'accepted' && updatedAt != null) {
          dateStr = _getDateString(updatedAt);
          groupType = 'hiring_requests_accepted';
        } else if (status == 'cancelled' && updatedAt != null) {
          dateStr = _getDateString(updatedAt);
          groupType = 'hiring_requests_cancelled';
        } else if (status == 'declined' && updatedAt != null) {
          dateStr = _getDateString(updatedAt);
          groupType = 'hiring_requests_declined_by_me';
        }
      } else if (headline == 'Hiring Request Cancelled' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'hiring_requests_cancelled';
      } else if (headline == 'Hiring Response') {
        final rawInfo = notification['information'];
        final info = rawInfo is String
            ? Map<String, dynamic>.from(jsonDecode(rawInfo))
            : Map<String, dynamic>.from(rawInfo ?? {});
        final action = info['action'] as String?;

        if (action == 'hire_declined' && createdAt != null) {
          dateStr = _getDateString(createdAt);
          groupType = 'hiring_requests_declined';
        } else if (action == 'hire_accepted' && createdAt != null) {
          dateStr = _getDateString(createdAt);
          groupType = 'hiring_requests_accepted';
        }
      } else if (headline == 'Bid Accepted' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'bid_accepted';
      } else if (headline == 'Bid Rejected' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'bid_rejected';
      } else if (headline == 'Bid Cancelled' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'bid_cancelled';
      } else if (headline == 'Project Bids Update' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'project_bids_update';
      } else if (headline == 'New Bid' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'new_bids';
      } else if (headline == 'Hiring Request Declined' && createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'hiring_requests_declined';
      } else if ((headline == 'Contract Signed' ||
                  headline == 'Contract Activated' ||
                  headline == 'Contract Rejected') &&
          createdAt != null) {
        dateStr = _getDateString(createdAt);
        groupType = 'contract_status';
      } else if (headline == 'Project Cancellation Request') {
        final rawInfo = notification['information'];
        final info = rawInfo is String
            ? Map<String, dynamic>.from(jsonDecode(rawInfo))
            : Map<String, dynamic>.from(rawInfo ?? {});
        final status = info['status'] as String?;
        final updatedAt = info['updated_at'] as String?;
        final senderType = notification['sender_type'] as String?;
        
        if (status == 'rejected' && updatedAt != null) {
          dateStr = _getDateString(updatedAt);
          groupType = 'cancellation_declined';
        } else {
        final isPending = status == null || status == 'pending' || status == '';
        final isSystemNotification = senderType == null || senderType == 'system';
        
          if ((isPending || isSystemNotification) && createdAt != null) {
            dateStr = _getDateString(createdAt);
            groupType = 'cancellation_request';
          }
        }
      }

      if (groupType != null && dateStr != null && dateStr.isNotEmpty) {
        final groupKey = '${groupType}_$dateStr';
        groups.putIfAbsent(groupKey, () => []).add(notification);
      } else {
        otherNotifications.add(notification);
        }
      }

    // Add other notifications
    if (otherNotifications.isNotEmpty) {
      groups['other'] = otherNotifications;
    }

    return groups;
  }

  Widget buildNotificationList(
      Stream<List<Map<String, dynamic>>> notificationStream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: notificationStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notifications'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text("No notifications yet"));
        }

        final groups = _groupNotifications(snapshot.data!);
        final otherNotifications = groups['other'] ?? [];

        // Sort groups by date (newest first) and type
        final sortedGroupKeys = groups.keys.where((key) => key != 'other').toList();
        sortedGroupKeys.sort((a, b) {
          // Extract date from key (format: 'type_YYYY-MM-DD')
          final partsA = a.split('_');
          final partsB = b.split('_');
          
          if (partsA.length < 3 || partsB.length < 3) return 0;
          
          final dateA = partsA.sublist(partsA.length - 3).join('-');
          final dateB = partsB.sublist(partsB.length - 3).join('-');
          
          if (dateA.isEmpty || dateB.isEmpty) return 0;
          return dateB.compareTo(dateA); // Newest first
        });

        return ListView(
          children: [
            ...sortedGroupKeys.map((groupKey) {
              final notifications = groups[groupKey]!;
              if (notifications.isEmpty) return const SizedBox.shrink();

              // Extract type and date from key
              final parts = groupKey.split('_');
              final dateStr = parts.length >= 3 
                  ? parts.sublist(parts.length - 3).join('-')
                  : '';
              final type = parts.length >= 3 
                  ? parts.sublist(0, parts.length - 3).join('_')
                  : groupKey;

              final dateLabel = _getDateLabel(dateStr);
              final title = _getGroupTitle(type, notifications.length, dateLabel);
              final icon = _getGroupIcon(type);

              return _buildGroupedNotification(
                title: title,
                icon: icon,
                notifications: notifications,
                groupKey: groupKey,
              );
            }),
            ...otherNotifications.map((notification) {
              return _buildSingleNotification(notification);
            }),
          ],
        );
      },
    );
  }

  String _getGroupTitle(String type, int count, String dateLabel) {
    switch (type) {
      case 'hiring_requests':
        return count == 1 ? 'Hiring Request' : '$count Hiring Requests';
      case 'hiring_requests_accepted':
        return count == 1 ? 'Hiring Request Accepted!' : '$count Hiring Requests Accepted!';
      case 'hiring_requests_cancelled':
        return count == 1 ? 'Hiring Request Cancelled' : '$count Hiring Requests Cancelled';
      case 'hiring_requests_declined_by_me':
        return count == 1 ? 'Hiring Request Declined' : '$count Hiring Requests Declined';
      case 'bid_accepted':
        return count == 1 ? 'Bid Accepted!' : '$count Bids Accepted!';
      case 'bid_rejected':
        return count == 1 ? 'Bid Not Accepted' : '$count Bids Not Accepted';
      case 'bid_cancelled':
        return count == 1 ? 'Bid Cancelled' : '$count Bids Cancelled';
      case 'project_bids_update':
        return count == 1 ? 'New Bids on Your Project' : '$count New Bids on Your Projects';
      case 'new_bids':
        return count == 1 ? 'New Bid Received' : '$count New Bids Received';
      case 'contract_status':
        return count == 1 ? 'Contract Update' : '$count Contract Updates';
      case 'cancellation_request':
        return count == 1 ? 'Cancellation Request' : '$count Cancellation Requests';
      case 'cancellation_declined':
        return count == 1 ? 'Cancellation Declined' : '$count Cancellations Declined';
      default:
        return count == 1 ? 'Notification' : '$count Notifications';
    }
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'hiring_requests':
        return Icons.work_outline;
      case 'hiring_requests_accepted':
      case 'bid_accepted':
        return Icons.check_circle_outline;
      case 'hiring_requests_cancelled':
      case 'bid_cancelled':
      case 'bid_rejected':
      case 'cancellation_request':
        return Icons.cancel_outlined;
      case 'hiring_requests_declined':
      case 'hiring_requests_declined_by_me':
      case 'cancellation_declined':
        return Icons.thumb_down_outlined;
      case 'project_bids_update':
        return Icons.gavel;
      case 'new_bids':
        return Icons.monetization_on;
      case 'contract_status':
        return Icons.description_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Widget _buildGroupedNotification({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> notifications,
    required String groupKey,
  }) {
    return _GroupedNotificationCard(
      title: title,
      icon: icon,
      notifications: notifications,
      groupKey: groupKey,
      receiverId: receiverId,
    );
  }

  Widget _buildSingleNotification(Map<String, dynamic> notification) {
    final rawInfo = notification['information'];
    final info = rawInfo is String
        ? Map<String, dynamic>.from(jsonDecode(rawInfo))
        : Map<String, dynamic>.from(rawInfo ?? {});

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchNotificationUserInfo(notification, info),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child:
                  Center(child: CircularProgressIndicator(color: Colors.amber)),
            ),
          );
        }

        final userInfo = snapshot.data ?? {};
        final senderName = userInfo['senderName'] ?? 'System';
        final senderPhoto = userInfo['senderPhoto'] ?? '';
        final notificationMessage =
            info['message'] ?? notification['message'] ?? '';
        final createdAt = notification['created_at']?.toString();
        final timeDisplay = formatLocalTime(createdAt);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: senderPhoto.isNotEmpty
                          ? NetworkImage(senderPhoto)
                          : const NetworkImage(
                              'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  senderName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (timeDisplay.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    timeDisplay,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification['headline'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  notificationMessage,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if ((notification['headline'] ?? '') ==
                    'Hiring Request') ...[
                  const SizedBox(height: 12),
                  _buildHiringRequestActions(notification, info),
                ],
                if ((notification['headline'] ?? '') ==
                    'Project Cancellation Request') ...[
                  const SizedBox(height: 12),
                  _buildCancellationRequestActions(notification, info),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchNotificationUserInfo(
      Map<String, dynamic> notification, Map<String, dynamic> info) async {
    final errorService = SuperAdminErrorService();
    try {
      final senderId =
          info['sender_id'] ?? info['contractee_id'] ?? info['contractor_id'];
      final projectId = info['project_id'];

      Map<String, dynamic> userInfo = {
        'senderName': 'System',
        'senderPhoto': '',
        'projectType': '',
      };

      if (senderId != null) {
        try {
          final contractorData =
              await FetchService().fetchContractorData(senderId);
          if (contractorData != null) {
            userInfo['senderName'] =
                contractorData['firm_name'] ?? 'Unknown Contractor';
            userInfo['senderPhoto'] = contractorData['profile_photo'] ?? '';
          } else {
            final contracteeData =
                await FetchService().fetchContracteeData(senderId);
            if (contracteeData != null) {
              userInfo['senderName'] =
                  contracteeData['full_name'] ?? 'Unknown Contractee';
              userInfo['senderPhoto'] = contracteeData['profile_photo'] ?? '';
            }
          }
        } catch (e) {
          errorService.logError(
            errorMessage: 'Error fetching sender data: $e',
            module: 'Notification UI Build Methods',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Fetch Sender Data',
              'sender_id': senderId,
              'receiver_id': receiverId,
            },
          );
        }
      }
      if (projectId != null) {
        try {
          final projectData =
              await FetchService().fetchProjectDetails(projectId);
          userInfo['projectType'] =
              projectData?['type'] ?? projectData?['title'] ?? '';
        } catch (e) {
          errorService.logError(
            errorMessage: 'Error fetching project data: $e',
            module: 'Notification UI Build Methods',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Fetch Project Data',
              'project_id': projectId,
              'receiver_id': receiverId,
            },
          );
          rethrow;
        }
      }

      return userInfo;
    } catch (e) {
      errorService.logError(
        errorMessage: 'Error in _fetchNotificationUserInfo: $e',
        module: 'Notification UI Build Methods',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Notification User Info',
          'receiver_id': receiverId,
        },
      );
      rethrow;
    }
  }

  Widget _buildCancellationRequestActions(
      Map<String, dynamic> notification, Map<String, dynamic> info) {
    final cancellationReason = info['cancellation_reason'] as String?;
    final status = info['status'] as String?;

    if (status == 'cancellation_requested_by_contractee' || status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cancellation Request',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The contractee has requested to cancel this project.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 13,
              ),
            ),
            if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: $cancellationReason',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Please check your project dashboard to approve or reject this request.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // If already approved/rejected, show status
    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cancellation approved',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cancellation rejected',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHiringRequestActions(
      Map<String, dynamic> notification, Map<String, dynamic> info) {
    final status = info['status'] as String?;

    if (status == 'cancelled') {
      final cancelledReason = info['cancellation_reason'] as String? ?? 
          info['cancelled_reason'] as String? ??
          info['cancel_message'] as String? ??
          'This request is no longer available';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cancelledReason,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'declined') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.close, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'You declined this request',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'You accepted this request',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Builder(
      builder: (builderContext) => Wrap(
        alignment: WrapAlignment.end,
        spacing: 4.0,
        runSpacing: 4.0,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
            onPressed: () => _showProjectDetailsDialog(builderContext, info),
            child: const Text('More Info', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget buildNotificationUI(
      Stream<List<Map<String, dynamic>>> notificationStream, {bool showAppBar = true}) {
    final isDesktopScreen = screenWidth > 1200;
    return isDesktopScreen
        ? Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                Container(
                  width: 450,
                  margin: const EdgeInsets.all(0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Notifications',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: buildNotificationList(notificationStream),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            appBar: showAppBar ? AppBar(
              title: const Text("Notifications",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFFFB300),
            ) : null,
            body: buildNotificationList(notificationStream),
          );
  }
}

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  Timer? _badgeTimer;
  int _unreadCount = 0;
  String? _receiverId;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadReceiverId();
    _loadUserType();
  }

  Future<void> _loadReceiverId() async {
    try {
      String? userType = await UserService().getCurrentUserType();
      String? id;

      if (userType?.toLowerCase() == 'contractee') {
        id = await UserService().getContracteeId();
      } else if (userType?.toLowerCase() == 'contractor') {
        id = await UserService().getContractorId();
      }

      if (id == null || !mounted) return;

      setState(() => _receiverId = id);

      _refreshBadge();

      _badgeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _refreshBadge();
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadUserType() async {
    try {
      final userType = await UserService().getCurrentUserType();
      if (mounted) {
        setState(() => _userType = userType);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshBadge() async {
    if (_receiverId == null || !mounted) return;

    try {
      final count = await NotificationService().getUnreadCount(_receiverId!);
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _unreadCount = 0);
      }
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () async {
            String? userType = await UserService().getCurrentUserType();

            if (userType == null) return;

            if (_isMobile(context)) {
              // Route within each app using GoRouter; both apps register '/notifications'.
              context.go('/notifications');
            } else {
              NotificationOverlay.show(context, userType);
            }
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationOverlay {
  static void show(BuildContext context, String userType) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withOpacity(0.1),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 400,
              height: MediaQuery.of(context).size.height * 0.8,
              margin: const EdgeInsets.only(top: 60, right: 20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.black),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<String?>(
                          future: userType.toLowerCase() == 'contractee'
                              ? UserService().getContracteeId()
                              : UserService().getContractorId(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.amber));
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(
                                child: Text('Failed to load notifications'),
                              );
                            }

                            final receiverId = snapshot.data!;
                            final notificationUIBuilder =
                                NotificationUIBuildMethods(
                              context: context,
                              receiverId: receiverId,
                            );

                            return notificationUIBuilder.buildNotificationList(
                              NotificationService()
                                  .listenToNotifications(receiverId),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOut,
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}

class _GroupedNotificationCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> notifications;
  final String groupKey;
  final String receiverId;

  const _GroupedNotificationCard({
    required this.title,
    required this.icon,
    required this.notifications,
    required this.groupKey,
    required this.receiverId,
  });

  @override
  State<_GroupedNotificationCard> createState() =>
      _GroupedNotificationCardState();
}

class _GroupedNotificationCardState extends State<_GroupedNotificationCard> {
  bool _isExpanded = false;

  Widget _buildGroupedHiringActions(
      Map<String, dynamic> notification, Map<String, dynamic> info) {
    final status = info['status'] as String?;

    if (status == 'cancelled') {
      final cancelledReason = info['cancelled_reason'] as String? ??
          'This request is no longer available';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cancelledReason,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'declined') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.close, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'You declined this request',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'You accepted this request',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Return empty container instead of action buttons
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: Colors.grey.shade700, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to ${_isExpanded ? 'collapse' : 'expand'} (${widget.notifications.length} ${widget.notifications.length == 1 ? 'notification' : 'notifications'})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
            if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade300),
                  ...widget.notifications.map((notification) {
                    return _buildNotificationItem(context, notification);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    final rawInfo = notification['information'];
    final info = rawInfo is String
        ? Map<String, dynamic>.from(jsonDecode(rawInfo))
        : Map<String, dynamic>.from(rawInfo ?? {});
    final createdAt = notification['created_at']?.toString();

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchNotificationUserInfo(notification, info),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
                child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        final userInfo = snapshot.data ?? {};
        final senderName = userInfo['senderName'] ?? 'System';
        final senderPhoto = userInfo['senderPhoto'] ?? '';
        final notificationMessage =
            info['message'] ?? notification['message'] ?? '';
        final timeDisplay = formatLocalTime(createdAt);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: senderPhoto.isNotEmpty
                        ? NetworkImage(senderPhoto)
                        : const NetworkImage(
                            'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                senderName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (timeDisplay.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  timeDisplay,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  notification['headline'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                notificationMessage,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if ((notification['headline'] ?? '') == 'Hiring Request') ...[
                const SizedBox(height: 12),
                _buildGroupedHiringActions(notification, info),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchNotificationUserInfo(
      Map<String, dynamic> notification, Map<String, dynamic> info) async {
    final errorService = SuperAdminErrorService();
    try {
      final senderId =
          info['sender_id'] ?? info['contractee_id'] ?? info['contractor_id'];
      final projectId = info['project_id'];

      Map<String, dynamic> userInfo = {
        'senderName': 'System',
        'senderPhoto': '',
        'projectType': '',
      };

      if (senderId != null) {
        try {
          final contractorData =
              await FetchService().fetchContractorData(senderId);
          if (contractorData != null) {
            userInfo['senderName'] =
                contractorData['firm_name'] ?? 'Unknown Contractor';
            userInfo['senderPhoto'] = contractorData['profile_photo'] ?? '';
          } else {
            final contracteeData =
                await FetchService().fetchContracteeData(senderId);
            if (contracteeData != null) {
              userInfo['senderName'] =
                  contracteeData['full_name'] ?? 'Unknown Contractee';
              userInfo['senderPhoto'] = contracteeData['profile_photo'] ?? '';
            }
          }
        } catch (e) {
          SuperAdminErrorService().logError(
            errorMessage: 'Error fetching sender data: $e',
            module: 'Notification Overlay',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Fetch Sender Data',
              'sender_id': senderId,
            },
          );
        }
      }

      if (projectId != null) {
        try {
          final projectData =
              await FetchService().fetchProjectDetails(projectId);
          userInfo['projectType'] =
              projectData?['type'] ?? projectData?['title'] ?? '';
        } catch (e) {
          errorService.logError(
            errorMessage: 'Error fetching project data: $e',
            module: 'Notification Overlay',
            severity: 'Medium',
            extraInfo: {
              'operation': 'Fetch Project Data',
              'project_id': projectId,
            },
          );
        }
      }

      return userInfo;
    } catch (e) {
      errorService.logError(
        errorMessage: 'Error in _fetchNotificationUserInfo: $e',
        module: 'Notification Overlay',
        severity: 'Medium',
        extraInfo: {
          'operation': 'Fetch Notification User Info',
        },
      );
      return {
        'senderName': 'System',
        'senderPhoto': '',
        'projectType': '',
      };
    }
  }
}

Future<void> _showProjectDetailsDialog(BuildContext context, Map<String, dynamic> info) {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Text('Project Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info['photo_url'] != null && info['photo_url'].toString().isNotEmpty) ...[
              _buildProjectPhoto(dialogContext, info['photo_url']),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Title:', info['project_title'] ?? 'N/A'),
            _buildDetailRow('Type:', info['project_type'] ?? 'N/A'),
            _buildDetailRow('Location:', info['project_location'] ?? 'N/A'),
            _buildDetailRow('Description:', info['project_description'] ?? 'N/A'),
            if (info['min_budget'] != null)
              _buildDetailRow('Min Budget:', '\$${info['min_budget']}'),
            if (info['max_budget'] != null)
              _buildDetailRow('Max Budget:', '\$${info['max_budget']}'),
            if (info['start_date'] != null)
              _buildDetailRow('Start Date:', info['start_date']),
            _buildDetailRow('Contractee:', info['full_name'] ?? info['firm_name'] ?? 'N/A'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _getProjectPhotoUrl(dynamic photoUrl) {
  if (photoUrl == null || photoUrl.toString().isEmpty) {
    return '';
  }
  final raw = photoUrl.toString();
  if (raw.startsWith('data:') || raw.startsWith('http')) {
    return raw;
  }
  try {
    return Supabase.instance.client.storage
        .from('projectphotos')
        .getPublicUrl(raw);
  } catch (_) {
    return raw;
  }
}

void _showFullPhotoDialog(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final size = MediaQuery.of(dialogContext).size;
      final double maxWidth = size.width * 0.75;
      final double maxHeight = size.height * 0.7;

      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildProjectPhoto(BuildContext context, dynamic photoUrl) {
  final photoUrlString = _getProjectPhotoUrl(photoUrl);
  if (photoUrlString.isEmpty) {
    return const SizedBox.shrink();
  }
  
  return GestureDetector(
    onTap: () => _showFullPhotoDialog(context, photoUrlString),
    child: Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(
              photoUrlString,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}



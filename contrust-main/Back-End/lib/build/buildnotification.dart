// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:backend/services/both%20services/be_notification_service.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/superadmin%20services/errorlogs_service.dart';
import 'package:contractee/pages/cee_notification.dart';
import 'package:contractor/Screen/cor_notification.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/both%20services/be_project_service.dart';

class NotificationUIBuildMethods {
  NotificationUIBuildMethods({
    required this.context,
    required this.receiverId,
  });

  final BuildContext context;
  final String receiverId;

  double get screenWidth => MediaQuery.of(context).size.width;
  bool get isDesktop => screenWidth > 1200;

  Map<String, List<Map<String, dynamic>>> _groupNotifications(List<Map<String, dynamic>> notifications) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final Map<String, List<Map<String, dynamic>>> groups = {
      'hiring_requests_today': [],
      'bid_accepted_today': [],
      'other': [],
    };
    
    for (var notification in notifications) {
      final createdAt = notification['created_at'] as String?;
      final headline = notification['headline'] as String?;
      
      if (createdAt != null && createdAt.startsWith(todayStr)) {
        if (headline == 'Hiring Request') {
          final rawInfo = notification['information'];
          final info = rawInfo is String
              ? Map<String, dynamic>.from(jsonDecode(rawInfo))
              : Map<String, dynamic>.from(rawInfo ?? {});
          final status = info['status'] as String?;
          
          if (status == null || status == 'pending') {
            groups['hiring_requests_today']!.add(notification);
            continue;
          }
        } else if (headline == 'Bid Accepted') {
          groups['bid_accepted_today']!.add(notification);
          continue;
        }
      }
      groups['other']!.add(notification);
    }
    
    return groups;
  }

  Widget buildNotificationList(Stream<List<Map<String, dynamic>>> notificationStream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: notificationStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notifications'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text("No notifications yet"));
        }
        
        final groups = _groupNotifications(snapshot.data!);
        final hiringRequestsToday = groups['hiring_requests_today']!;
        final bidAcceptedToday = groups['bid_accepted_today']!;
        final otherNotifications = groups['other']!;
        
        return ListView(
          children: [
            if (hiringRequestsToday.isNotEmpty)
              _buildGroupedNotification(
                title: 'You have ${hiringRequestsToday.length} hiring ${hiringRequestsToday.length == 1 ? 'request' : 'requests'} today',
                icon: Icons.work_outline,
                color: Colors.blue,
                notifications: hiringRequestsToday,
                groupKey: 'hiring_requests_today',
              ),
            
            if (bidAcceptedToday.isNotEmpty)
              _buildGroupedNotification(
                title: 'You have ${bidAcceptedToday.length} ${bidAcceptedToday.length == 1 ? 'bid' : 'bids'} today',
                icon: Icons.trending_up,
                color: Colors.green,
                notifications: bidAcceptedToday,
                groupKey: 'bid_accepted_today',
              ),

            ...otherNotifications.map((notification) {
              return _buildSingleNotification(notification);
            }),
          ],
        );
      },
    );
  }
  
  Widget _buildGroupedNotification({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> notifications,
    required String groupKey,
  }) {
    return _GroupedNotificationCard(
      title: title,
      icon: icon,
      color: color,
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
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userInfo = snapshot.data ?? {};
        final senderName = userInfo['senderName'] ?? 'System';
        final senderPhoto = userInfo['senderPhoto'] ?? '';
        final projectType = userInfo['projectType'] ?? '';
    final notificationMessage = info['message'] ?? notification['message'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: senderPhoto.isNotEmpty
                            ? NetworkImage(senderPhoto)
                            : const AssetImage('defaultpic.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (projectType.isNotEmpty)
                              Text(
                                projectType,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notification['headline'] ?? '',
                    style: const TextStyle(
                              fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notificationMessage,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  if ((notification['headline'] ?? '') == 'Hiring Request') ...[
                    const SizedBox(height: 12),
                    _buildHiringRequestActions(notification, info),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchNotificationUserInfo(Map<String, dynamic> notification, Map<String, dynamic> info) async {
    final errorService = SuperAdminErrorService();
    try {
      final senderId = info['sender_id'] ?? info['contractor_id'] ?? info['contractee_id'];
      final projectId = info['project_id'];
      
      Map<String, dynamic> userInfo = {
        'senderName': 'System',
        'senderPhoto': '',
        'projectType': '',
      };

      // Fetch sender information
      if (senderId != null) {
        try {
          // Try to fetch as contractor first
          final contractorData = await FetchService().fetchContractorData(senderId);
          if (contractorData != null) {
            userInfo['senderName'] = contractorData['firm_name'] ?? 'Unknown Contractor';
            userInfo['senderPhoto'] = contractorData['profile_photo'] ?? '';
          } else {
            // If not found as contractor, try as contractee
            final contracteeData = await FetchService().fetchContracteeData(senderId);
            if (contracteeData != null) {
              userInfo['senderName'] = contracteeData['full_name'] ?? 'Unknown Contractee';
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
          final projectData = await FetchService().fetchProjectDetails(projectId);
          userInfo['projectType'] = projectData?['type'] ?? projectData?['title'] ?? '';
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

  Widget _buildHiringRequestActions(Map<String, dynamic> notification, Map<String, dynamic> info) {
    final status = info['status'] as String?;
    
    if (status == 'cancelled') {
      final cancelledReason = info['cancelled_reason'] as String? ?? 'This request is no longer available';
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
    
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () async {
            await ProjectService().declineHiring(
              notificationId: notification['notification_id'],
              contractorId: receiverId,
              contracteeId: info['contractee_id'],
            );
          },
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () async {
            await ProjectService().acceptHiring(
              notificationId: notification['notification_id'],
              contractorId: receiverId,
              contracteeId: info['contractee_id'],
              projectId: info['project_id'],
            );
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }

  Widget buildNotificationUI(Stream<List<Map<String, dynamic>>> notificationStream) {
    return isDesktop
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
            appBar: AppBar(
              title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.amber[500],
            ),
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
    return Theme.of(context).platform == TargetPlatform.android;
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
              if (userType.toLowerCase() == 'contractee') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContracteeNotificationPage(),
                  ),
                );
              } else if (userType.toLowerCase() == 'contractor') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContractorNotificationPage(),
                  ),
                );
              }
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
  static Future<Map<String, dynamic>> _fetchNotificationUserInfo(Map<String, dynamic> notification, Map<String, dynamic> info) async {
    try {
      final senderId = info['sender_id'] ?? info['contractor_id'] ?? info['contractee_id'];
      final projectId = info['project_id'];
      
      Map<String, dynamic> userInfo = {
        'senderName': 'System',
        'senderPhoto': '',
        'projectType': '',
      };

      if (senderId != null) {
        try {
          final contractorData = await FetchService().fetchContractorData(senderId);
          if (contractorData != null) {
            userInfo['senderName'] = contractorData['firm_name'] ?? 'Unknown Contractor';
            userInfo['senderPhoto'] = contractorData['profile_photo'] ?? '';
          } else {
            final contracteeData = await FetchService().fetchContracteeData(senderId);
            if (contracteeData != null) {
              userInfo['senderName'] = contracteeData['full_name'] ?? 'Unknown Contractee';
              userInfo['senderPhoto'] = contracteeData['profile_photo'] ?? '';
            }
          }
        } catch (e) {
          SuperAdminErrorService().logError(
            errorMessage: 'Error fetching sender data: $e',
            module: 'Notification UI Build Methods',
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
          final projectData = await FetchService().fetchProjectDetails(projectId);
          userInfo['projectType'] = projectData?['type'] ?? projectData?['title'] ?? '';
        } catch (e) {
          SuperAdminErrorService().logError(
            errorMessage: 'Error fetching project data: $e',
            module: 'Notification UI Build Methods',
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
      SuperAdminErrorService().logError(
        errorMessage: 'Error in _fetchNotificationUserInfo: $e',
        module: 'Notification UI Build Methods',
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
                              icon: const Icon(Icons.close, color: Colors.black),
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
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(
                                child: Text('Failed to load notifications'),
                              );
                            }

                            final receiverId = snapshot.data!;
                            final notificationStream = NotificationService().listenToNotifications(receiverId);

                            return StreamBuilder<List<Map<String, dynamic>>>(
                              stream: notificationStream,
                              builder: (context, streamSnapshot) {
                                if (streamSnapshot.hasError) {
                                  return Center(
                                    child: Text('Error loading notifications'),
                                  );
                                }
                                if (!streamSnapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (streamSnapshot.data!.isEmpty) {
                                  return const Center(child: Text("No notifications yet"));
                                }

                                return ListView.builder(
                                  itemCount: streamSnapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final notification = streamSnapshot.data![index];
                                    final rawInfo = notification['information'];
                                    final info = rawInfo is String
                                        ? Map<String, dynamic>.from(jsonDecode(rawInfo))
                                        : Map<String, dynamic>.from(rawInfo ?? {});

                                    return FutureBuilder<Map<String, dynamic>>(
                                      future: NotificationOverlay._fetchNotificationUserInfo(notification, info),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Center(child: CircularProgressIndicator()),
                                            ),
                                          );
                                        }

                                        final userInfo = snapshot.data ?? {};
                                        final senderName = userInfo['senderName'] ?? 'System';
                                        final senderPhoto = userInfo['senderPhoto'] ?? '';
                                        final projectType = userInfo['projectType'] ?? '';
                                    final notificationMessage = info['message'] ?? notification['message'] ?? '';

                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundImage: senderPhoto.isNotEmpty
                                                      ? NetworkImage(senderPhoto)
                                                      : const AssetImage('defaultpic.png') as ImageProvider,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        senderName,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (projectType.isNotEmpty)
                                                        Text(
                                                          projectType,
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notification['headline'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notificationMessage,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
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
  final Color color;
  final List<Map<String, dynamic>> notifications;
  final String groupKey;
  final String receiverId;

  const _GroupedNotificationCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.notifications,
    required this.groupKey,
    required this.receiverId,
  });

  @override
  State<_GroupedNotificationCard> createState() => _GroupedNotificationCardState();
}

class _GroupedNotificationCardState extends State<_GroupedNotificationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to ${_isExpanded ? 'collapse' : 'view all'}',
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
                    color: widget.color,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  Divider(height: 1, color: widget.color.withOpacity(0.3)),
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

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notification) {
    final rawInfo = notification['information'];
    final info = rawInfo is String
        ? Map<String, dynamic>.from(jsonDecode(rawInfo))
        : Map<String, dynamic>.from(rawInfo ?? {});

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
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final userInfo = snapshot.data ?? {};
        final senderName = userInfo['senderName'] ?? 'System';
        final senderPhoto = userInfo['senderPhoto'] ?? '';
        final projectTitle = userInfo['projectType'] ?? '';
    final notificationMessage = info['message'] ?? notification['message'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: senderPhoto.isNotEmpty
                    ? NetworkImage(senderPhoto)
                    : const AssetImage('defaultpic.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (projectTitle.isNotEmpty)
                      Text(
                        projectTitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notificationMessage,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((notification['headline'] ?? '') == 'Hiring Request') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await ProjectService().declineHiring(
                      notificationId: notification['notification_id'],
                      contractorId: widget.receiverId,
                      contracteeId: info['contractee_id'],
                    );
                  },
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await ProjectService().acceptHiring(
                      notificationId: notification['notification_id'],
                      contractorId: widget.receiverId,
                      contracteeId: info['contractee_id'],
                      projectId: info['project_id'],
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ],
      ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchNotificationUserInfo(Map<String, dynamic> notification, Map<String, dynamic> info) async {
    final errorService = SuperAdminErrorService();
    try {
      final senderId = info['sender_id'] ?? info['contractor_id'] ?? info['contractee_id'];
      final projectId = info['project_id'];
      
      Map<String, dynamic> userInfo = {
        'senderName': 'System',
        'senderPhoto': '',
        'projectType': '',
      };

      // Fetch sender information
      if (senderId != null) {
        try {
          // Try to fetch as contractor first
          final contractorData = await FetchService().fetchContractorData(senderId);
          if (contractorData != null) {
            userInfo['senderName'] = contractorData['firm_name'] ?? 'Unknown Contractor';
            userInfo['senderPhoto'] = contractorData['profile_photo'] ?? '';
          } else {
            // If not found as contractor, try as contractee
            final contracteeData = await FetchService().fetchContracteeData(senderId);
            if (contracteeData != null) {
              userInfo['senderName'] = contracteeData['full_name'] ?? 'Unknown Contractee';
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
          final projectData = await FetchService().fetchProjectDetails(projectId);
          userInfo['projectType'] = projectData?['type'] ?? projectData?['title'] ?? '';
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
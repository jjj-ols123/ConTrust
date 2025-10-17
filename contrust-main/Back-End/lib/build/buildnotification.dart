// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:backend/services/both%20services/be_notification_service.dart';
import 'package:backend/services/both%20services/be_user_service.dart';
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
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final notification = snapshot.data![index];

            final rawInfo = notification['information'];
            final info = rawInfo is String
                ? Map<String, dynamic>.from(jsonDecode(rawInfo))
                : Map<String, dynamic>.from(rawInfo ?? {});

            final senderName = info['contractor_name'] ?? info['full_name'] ?? 'System';
            final senderPhoto = info['contractor_photo'] ?? info['profile_photo'] ?? '';
            final projectType = info['project_type'] ?? '';
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
                            OverflowBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    final info = notification['information'] is String
                                        ? Map<String, dynamic>.from(jsonDecode(notification['information']))
                                        : Map<String, dynamic>.from(notification['information'] ?? {});
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
                                    final info = notification['information'] is String
                                        ? Map<String, dynamic>.from(jsonDecode(notification['information']))
                                        : Map<String, dynamic>.from(notification['information'] ?? {});
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
                            ),
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
      },
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

                                    final senderName = info['contractor_name'] ?? info['full_name'] ?? 'System';
                                    final senderPhoto = info['contractor_photo'] ?? info['profile_photo'] ?? '';
                                    final projectType = info['project_type'] ?? '';
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

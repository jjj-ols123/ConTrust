import 'dart:convert'; // 🔥 add this
import 'package:backend/services/be_notification_service.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:flutter/material.dart';

class ContractorNotificationPage extends StatefulWidget {
  const ContractorNotificationPage({super.key});

  @override
  State<ContractorNotificationPage> createState() =>
      _ContractorNotificationPageState();
}

class _ContractorNotificationPageState
    extends State<ContractorNotificationPage> {
  String? contractorId;

  @override
  void initState() {
    super.initState();
    _loadReceiverId();
  }

  Future<void> _loadReceiverId() async {
    final id = await UserService().getContractorId();
    setState(() => contractorId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (contractorId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService().listenToNotifications(contractorId!),
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

              final senderName = info['full_name'] ?? 'System';
              final senderPhoto = info['profile_photo'] ?? '';
              final projectType = info['project_type'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: senderPhoto.isNotEmpty
                      ? NetworkImage(senderPhoto)
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
                ),
                title: Text(
                  notification['headline'] ?? 'Notification',
                  style: TextStyle(
                    fontWeight: notification['is_read'] == true
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (projectType.isNotEmpty)
                      Text('Project: $projectType'),
                    Text('From: $senderName'),
                  ],  
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(notification['created_at']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (notification['is_read'] != true)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  if (notification['is_read'] != true) {
                    NotificationService()
                        .markAsRead(notification['notification_id']);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}

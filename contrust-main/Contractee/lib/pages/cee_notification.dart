import 'dart:convert';

import 'package:backend/services/be_notification_service.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:flutter/material.dart';

class ContracteeNotificationPage extends StatefulWidget {
  const ContracteeNotificationPage({super.key});

  @override
  State<ContracteeNotificationPage> createState() =>
      _ContracteeNotificationPageState();
}

class _ContracteeNotificationPageState
    extends State<ContracteeNotificationPage> {
  String? contracteeId;

  @override
  void initState() {
    super.initState();
    _loadReceiverId();
  }

  Future<void> _loadReceiverId() async {
    final id = await UserService().getContracteeId();
    setState(() => contracteeId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (contracteeId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService().listenToNotifications(contracteeId!),
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

              final info = notification['information'] is String
                  ? Map<String, dynamic>.from(
                      jsonDecode(notification['information']))
                  : Map<String, dynamic>.from(notification['information'] ?? {});
              final contractorName = info['contractor_name'] as String? ?? 'Unknown';
              final contractorPhoto = info['contractor_photo'] as String? ?? '';
              final bidAmount = info['bid_amount'] as num? ?? 0;

              return ListTile(

                leading: CircleAvatar(
                  backgroundImage: contractorPhoto.isNotEmpty
                      ? NetworkImage(contractorPhoto)
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
                    Text('Bid: ₱$bidAmount'),
                    Text('By: $contractorName'),
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
                    NotificationService().markAsRead(notification['notification_id']);
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

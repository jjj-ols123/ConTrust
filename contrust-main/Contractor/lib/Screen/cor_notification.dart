import 'dart:convert';
import 'package:backend/services/be_notification_service.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:backend/services/be_user_service.dart';
import 'package:contractor/models/cor_UInotif.dart';
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

  Future<void> _acceptHiring(String notificationId, Map<String, dynamic> info) async {
    try {
      await ProjectService().acceptHiring(
        notificationId: notificationId,
        contractorId: contractorId!,
        contracteeId: info['contractee_id'],
        projectId: info['project_id'], 
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hiring request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept hiring request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineHiring(String notificationId, Map<String, dynamic> info) async {
    try {
      await ProjectService().declineHiring(
        notificationId: notificationId,
        contractorId: contractorId!,
        contracteeId: info['contractee_id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hiring request declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline hiring request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: senderPhoto.isNotEmpty
                                ? NetworkImage(senderPhoto)
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${notification['headline'] ?? 'Notification'} from $senderName',
                                  style: TextStyle(
                                    fontWeight: notification['is_read'] == true
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(notification['created_at']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 52), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info['message'] ?? '',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            if (projectType.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Project: $projectType',
                                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (notification['headline'] == 'Hiring Request' &&
                          info['status'] != 'accepted' &&
                          info['status'] != 'declined')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _declineHiring(notification['notification_id'], info),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    _acceptHiring(notification['notification_id'], info),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ),
                      if (notification['headline'] == 'Hiring Request')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () => UINotifCor().showProjectDetails(context, info),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: const Text('View Project Details'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      if (info['status'] == 'accepted' || info['status'] == 'declined')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: info['status'] == 'accepted' ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                info['status'] == 'accepted' ? 'Accepted' : 'Declined',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      if (info['status'] == 'cancelled')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'This hiring request has been cancelled',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                info['cancelled_reason'] ?? 'Project no longer available',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
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

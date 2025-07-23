// ignore_for_file: use_build_context_synchronously

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
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.amber.shade100,
                            backgroundImage: senderPhoto.isNotEmpty
                                ? NetworkImage(senderPhoto)
                                : const AssetImage('defaultpic.png') as ImageProvider,
                            child: notification['headline'] == 'Hiring Request'
                                ? const Icon(Icons.business_center, color: Colors.amber, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      notification['headline'] == 'Hiring Request'
                                          ? Icons.mail_outline
                                          : Icons.notifications,
                                      color: notification['is_read'] == true ? Colors.grey : Colors.amber[800],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${notification['headline'] ?? 'Notification'}',
                                      style: TextStyle(
                                        fontWeight: notification['is_read'] == true
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'From: $senderName',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 58),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((notification['message'] ?? '').isNotEmpty)
                              Text(
                                notification['message'],
                                style: const TextStyle(fontSize: 15, color: Colors.black87),
                              ),
                            if ((info['message'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  info['message'],
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
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
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _declineHiring(notification['notification_id'], info),
                                icon: const Icon(Icons.close, color: Colors.red),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                label: const Text('Decline'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Accept Hiring Request'),
                                      content: const Text('Are you sure you want to accept this hiring request?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: const Text('Accept'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    _acceptHiring(notification['notification_id'], info);
                                  }
                                },
                                icon: const Icon(Icons.check, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                label: const Text('Accept'),
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
                      if (info['status'] == 'cancelled' || info['status'] == 'deleted')
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Text(
                                info['deleted_reason'] ?? info['cancelled_reason'] ?? 'This hiring request is no longer available.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (info['deleted_at'] != null)
                                Text(
                                  'Deleted at: ${info['deleted_at']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (notification['headline'] == 'Project Cancellation Request' && info['status'] == 'cancelled') ...[
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await ProjectService().agreeCancelAgreement(info['project_id'], contractorId!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You agreed to cancel the project.')),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Agree'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                await ProjectService().declineCancelAgreement(info['project_id'], contractorId!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You declined the cancellation.')),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Decline'),
                            ),
                          ],
                        ),
                      ],
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

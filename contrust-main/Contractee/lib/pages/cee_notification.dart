// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:backend/services/be_notification_service.dart';
import 'package:backend/services/be_project_service.dart';
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
                  : Map<String, dynamic>.from(
                      notification['information'] ?? {});
              
              final contractorName =
                  info['contractor_name'] ?? info['firm_name'] ?? 'Unknown';
              final contractorPhoto = info['contractor_photo'] as String? ?? '';
              final bidAmount = info['bid_amount'] as num? ?? 0;


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
                            backgroundImage: contractorPhoto.isNotEmpty
                                ? NetworkImage(contractorPhoto)
                                : const AssetImage('defaultpic.png') as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['headline'] ?? 'Notification',
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDate(notification['created_at']),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (notification['is_read'] != true)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 52), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (notification['headline'] == 'Hiring Response')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Response: ${info['message'] ?? ''}',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'From: $contractorName',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bid: ₱$bidAmount',
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By: $contractorName',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (notification['headline'] == 'Hiring Response')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: info['action'] == 'hire_accepted' ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                info['action'] == 'hire_accepted' ? 'Accepted' : 'Declined',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      if (notification['headline'] == 'Project Cancellation Request' && info['status'] == 'cancelled') ...[
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await ProjectService().agreeCancelAgreement(info['project_id'], contracteeId!);
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
                                await ProjectService().declineCancelAgreement(info['project_id'], contracteeId!);
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

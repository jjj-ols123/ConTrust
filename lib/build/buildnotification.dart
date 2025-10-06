// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
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

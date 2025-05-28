import 'package:backend/services/getuserdata.dart';
import 'package:backend/services/notification.dart';
import 'package:backend/models/notificationmodal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContracteeNotificationPage extends StatefulWidget {
  const ContracteeNotificationPage({super.key});

  @override
  State<ContracteeNotificationPage> createState() =>
      _ContracteeNotificationPageState();
}

class _ContracteeNotificationPageState
    extends State<ContracteeNotificationPage> {
  final NotificationService notificationService = NotificationService();
  String? contracteeId;

  @override
  void initState() {
    super.initState();
    initReceiverId();
  }

  Future<void> initReceiverId() async {
    final id = await GetUserId().getContracteeId();
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
        stream: notificationService.listenNotification(contracteeId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notifications: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          final notifications =
              snapshot.data!.map((e) => NotificationModel.fromMap(e)).toList();

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                title: Text(
                  notif.headline,
                  style: TextStyle(
                    fontWeight:
                        notif.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle:
                    Text(DateFormat.yMMMd().add_jm().format(notif.createdAt)),
                trailing: notif.isRead
                    ? const Icon(Icons.mark_email_read_outlined,
                        color: Colors.grey)
                    : const Icon(Icons.mark_email_unread_outlined,
                        color: Colors.blue),
                onTap: () async {
                  if (!notif.isRead) {
                    await notificationService.readNotification(notif.id);
                    setState(() {});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

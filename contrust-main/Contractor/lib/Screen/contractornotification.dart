import 'package:backend/services/getuserdata.dart';
import 'package:backend/services/notification.dart';
import 'package:contractee/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractorNotificationPage extends StatefulWidget {
  const ContractorNotificationPage({super.key});

  @override
  State<ContractorNotificationPage> createState() =>
      _ContractorNotificationPageState();
}

class _ContractorNotificationPageState
    extends State<ContractorNotificationPage> {
  final NotificationService notificationService = NotificationService();
  String? contracteeId;

  @override
  void initState() {
    super.initState();
    initReceiverId();
  }

  Future<void> initReceiverId() async {
    final id = await GetUserId().getContractorId();
    setState(() => contracteeId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (contracteeId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.listenNotification(contracteeId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          final notifications =
              snapshot.data!.map((e) => NotificationModel.fromMap(e)).toList();

          return ListView.builder(
            itemCount: notifications.length,
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

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
    initReceiverId();
  }

  Future<void> initReceiverId() async {
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
              child: Text('Error loading notifications: ${snapshot.error}'),
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
              return ListTile(
                title: Text(notification['title'] ?? 'No Title'),
                subtitle: Text(notification['body'] ?? 'No Body'),
              );
            },
          );
        },
      ),
    );
  }
}

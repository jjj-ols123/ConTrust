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
  String? contracteeId;

  @override
  void initState() {
    super.initState();
    initReceiverId();
  }

  Future<void> initReceiverId() async {
    final id = await UserService().getContractorId();
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
        stream: NotificationService().listenToNotifications(contracteeId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }          return ListView.builder(
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

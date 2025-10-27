// ignore_for_file: use_build_context_synchronously

import 'package:backend/build/buildnotification.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/both services/be_user_service.dart';
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
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final notificationUIBuilder = NotificationUIBuildMethods(
      context: context,
      receiverId: contracteeId!,
    );

    return notificationUIBuilder.buildNotificationUI(
      NotificationService().listenToNotifications(contracteeId!),
    );
  }
}

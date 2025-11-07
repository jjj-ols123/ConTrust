// ignore_for_file: use_build_context_synchronously

import 'package:backend/build/buildnotification.dart';
import 'package:backend/services/both services/be_notification_service.dart';
import 'package:backend/services/both services/be_user_service.dart';
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
    loadReceiverId();
  }

  Future<void> loadReceiverId() async {
    final id = await UserService().getContractorId();
    setState(() => contractorId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (contractorId == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    final notificationUIBuilder = NotificationUIBuildMethods(
      context: context,
      receiverId: contractorId!,
    );

    return notificationUIBuilder.buildNotificationUI(
      NotificationService().listenToNotifications(contractorId!),
      showAppBar: false,
    );
  }
}

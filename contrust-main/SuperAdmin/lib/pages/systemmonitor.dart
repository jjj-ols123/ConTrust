import 'package:flutter/material.dart';
import '../build/buildsystem.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key});

  @override
  SystemMonitorPageState createState() => SystemMonitorPageState();
}

class SystemMonitorPageState extends State<SystemMonitorPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SystemMonitorTable(),
    );
  }
}

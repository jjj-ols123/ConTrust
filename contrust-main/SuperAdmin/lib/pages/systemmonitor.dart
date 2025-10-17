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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'System Monitor',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.grey),
            onPressed: () {
      
              setState(() {});
            },
            tooltip: 'Refresh All',
          ),
        ],
      ),
      body: const SystemMonitorTable(),
    );
  }
}

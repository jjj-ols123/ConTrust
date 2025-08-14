// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use
import 'package:backend/models/be_appbar.dart';
import 'package:contractor/models/cor_UIdashboard.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  final String contractorId;
  const DashboardScreen({super.key, required this.contractorId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConTrustAppBar(
        headline: "Dashboard",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {

            },
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.contractorId.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {

                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: DashboardUI(contractorId: widget.contractorId),
                    ),
                  ),
                ),
          PersistentDashboardDrawer(contractorId: widget.contractorId),
        ],
      ),
    );
  }
}

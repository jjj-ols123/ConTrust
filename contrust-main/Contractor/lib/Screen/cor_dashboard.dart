// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use
import 'package:backend/services/contractor services/cor_dashboardservice.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/builddashboard.dart';
import 'package:contractor/build/builddrawer.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebSize = screenWidth >= 1000;
    
    return Scaffold(
      body: ContractorShell(
        currentPage: ContractorPage.dashboard,
        contractorId: widget.contractorId,
        child: widget.contractorId.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : isWebSize
                ? DashboardUI(contractorId: widget.contractorId)
                : Stack(
                    children: [
                      DashboardUI(contractorId: widget.contractorId),
                      BottomDashboardDrawer(contractorId: widget.contractorId),
                    ],
                  ),
      ),
    );
  }
}

class DashboardUI extends StatefulWidget {
  final String? contractorId;
  const DashboardUI({super.key, required this.contractorId});

  @override
  State<DashboardUI> createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI>
    with TickerProviderStateMixin {

  final dashboardService = CorDashboardService();
  
  Map<String, dynamic>? contractorData;
  int activeProjects = 0;
  int completedProjects = 0;
  double rating = 0.0;
  bool loading = true;
  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> localTasks = [];
  double totalEarnings = 0.0;
  int totalClients = 0;  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    fetchDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    try {
      if (widget.contractorId == null) {
        setState(() => loading = false);
        return;
      }

      setState(() => loading = true);
      
      final data = await dashboardService.loadDashboardData(widget.contractorId!);
      
      setState(() {
        contractorData = data['contractorData'];
        activeProjects = data['activeProjects'];
        completedProjects = data['completedProjects'];
        rating = data['rating'];
        recentActivities = data['recentActivities'];
        totalEarnings = data['totalEarnings'];
        totalClients = data['totalClients'];
        localTasks = data['localTasks'];
        loading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading dashboard data. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text('Loading your dashboard...'),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Column(
      children: [
        Container(
            height: 60,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.dashboard, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dashboard',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      RefreshIndicator(
      onRefresh: fetchDashboardData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isDesktop) ...[
                  buildWelcomeCard(),
                  const SizedBox(height: 20),
                ],
                buildStatsGrid(),
                const SizedBox(height: 20),
                if (isDesktop)
                  buildDesktopProjectsAndTasks()
                else
                  buildMobileProjectsAndTasks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    )
      ],
    );
  }

  Widget buildWelcomeCard() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
    );
    buildMethods.contractorData = contractorData;
    return buildMethods.buildWelcomeCard();
  }

  Widget buildStatsGrid() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
    );
    return buildMethods.buildStatsGrid();
  }

  Widget buildDesktopProjectsAndTasks() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.localTasks = localTasks;
    return buildMethods.buildDesktopProjectsAndTasks();
  }

  Widget buildMobileProjectsAndTasks() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.localTasks = localTasks;
    return buildMethods.buildMobileProjectsAndTasks();
  }
}

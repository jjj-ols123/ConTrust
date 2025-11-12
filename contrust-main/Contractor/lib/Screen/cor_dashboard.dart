// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use
import 'dart:async';
import 'package:backend/services/contractor services/cor_dashboardservice.dart';
import 'package:backend/services/both services/be_realtime_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/builddashboard.dart';
import 'package:flutter/material.dart' hide BottomNavigationBar;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.user.id.isEmpty) {
        context.go('/logincontractor');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.contractorId.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : DashboardUI(contractorId: widget.contractorId);
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
  final realtimeService = RealtimeSubscriptionService();
  
  Map<String, dynamic>? contractorData;
  int activeProjects = 0;
  int completedProjects = 0;
  double rating = 0.0;
  int totalReviews = 0;
  bool loading = true;
  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> localTasks = [];
  double totalEarnings = 0.0;
  List<Map<String, dynamic>> allPayments = [];
  int totalClients = 0;
  Timer? _debounceTimer;
  late AnimationController _fadeController;
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
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.contractorId != null) {
      realtimeService.unsubscribeFromUserChannels(widget.contractorId!);
    }
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
        totalReviews = data['totalReviews'] ?? 0;
        recentActivities = data['recentActivities'];
        totalEarnings = data['totalEarnings'];
        allPayments = List<Map<String, dynamic>>.from(data['allPayments'] ?? []);
        totalClients = data['totalClients'];
        localTasks = data['localTasks'];
        loading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ConTrustSnackBar.error(context, 'Error loading dashboard data. Please try again.');
      }
    }
  }

  Future<void> _setupRealtimeSubscriptions() async {
    if (widget.contractorId == null) return;

    void debouncedFetchData() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          fetchDashboardData();
        }
      });
    }

    realtimeService.subscribeToNotifications(
      userId: widget.contractorId!,
      onUpdate: debouncedFetchData,
    );

    realtimeService.subscribeToContractorProjects(
      userId: widget.contractorId!,
      onUpdate: debouncedFetchData,
    );

    realtimeService.subscribeToContractorBids(
      userId: widget.contractorId!,
      onUpdate: debouncedFetchData,
    );
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

    if (isDesktop) {
      return RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: buildDesktopProjectsAndTasks(),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
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
                _buildVerificationBanner(),
                const SizedBox(height: 20),
                buildWelcomeCard(),
                const SizedBox(height: 20),
                buildStatsGrid(),
                const SizedBox(height: 20),
                buildHiringRequestContainer(),
                const SizedBox(height: 20),
                buildMobileProjectsAndTasks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return FutureBuilder<bool>(
      future: _checkVerificationStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        final isVerified = snapshot.data ?? false;
        if (isVerified) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Pending Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your account is being reviewed. Some features are disabled until verification is complete.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkVerificationStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      final resp = await Supabase.instance.client
          .from('Users')
          .select('verified')
          .eq('users_id', session.user.id)
          .maybeSingle();

      return resp != null && (resp['verified'] == true);
    } catch (e) {
      return false;
    }
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
      totalReviews,
      onDataRefresh: fetchDashboardData,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.allPayments = allPayments;
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
      totalReviews,
      onDataRefresh: fetchDashboardData,
    );
    buildMethods.allPayments = allPayments;
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
      totalReviews,
      onDataRefresh: fetchDashboardData,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.allPayments = allPayments;
    buildMethods.localTasks = localTasks;
    return buildMethods.buildDesktopProjectsAndTasks();
  }

  Widget buildHiringRequestContainer() {
    final buildMethods = DashboardBuildMethods(
      context,
      recentActivities,
      activeProjects,
      completedProjects,
      totalEarnings,
      totalClients,
      rating,
      totalReviews,
      onDataRefresh: fetchDashboardData,
    );
    return buildMethods.buildHiringRequestContainer();
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
      totalReviews,
      onDataRefresh: fetchDashboardData,
    );
    buildMethods.contractorData = contractorData;
    buildMethods.allPayments = allPayments;
    buildMethods.localTasks = localTasks;
    return buildMethods.buildMobileProjectsAndTasks();
  }
}

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:backend/services/contractor services/cor_dashboardservice.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/build/buildviewcontract.dart';
import 'package:backend/services/contractor services/contract/cor_viewcontractservice.dart';
import 'package:contractor/build/builddashboardtabs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardBuildMethods {
  DashboardBuildMethods(
    this.context,
    this.recentActivities,
    this.activeProjects,
    this.completedProjects,
    this.totalEarnings,
    this.totalClients,
    this.rating, {
    this.onDataRefresh,
  });

  final BuildContext context;
  final VoidCallback? onDataRefresh;
  final ProjectStatus status = ProjectStatus();
  final CorDashboardService dashboardservice = CorDashboardService();

  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> localTasks = [];
  List<Map<String, dynamic>> pendingHiringRequests = [];
  Map<String, dynamic>? contractorData;

  int activeProjects = 0;
  int completedProjects = 0;
  double totalEarnings = 0.0;
  List<Map<String, dynamic>> allPayments = [];
  int totalClients = 0;
  double rating = 0.0;

  double get screenWidth => MediaQuery.of(context).size.width;
  bool get isDesktop => screenWidth >= 1200;
  bool get isTablet => screenWidth >= 700 && screenWidth < 1200;
  bool get isMobile => screenWidth < 700;

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

  Widget buildDesktopProjectsAndTasks() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVerificationBanner(),
                    const SizedBox(height: 20),
                    buildWelcomeCard(),
                    const SizedBox(height: 20),
                    buildTabbedProjectView(),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: screenWidth * 0.25,
          child: Column(
            children: [
              buildDesktopStatsContainer(),
              const SizedBox(height: 20),
              buildHiringRequestContainer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTabbedProjectView() {
    return DashboardProjectTabs(
      activeProjects: _getProjectsToShow(),
      buildProjectSection: (selectedProject) => buildSingleProjectView(selectedProject),
      buildContracteeSection: (selectedProject) => buildCurrentContracteeContainer(selectedProject),
      buildTasksSection: (selectedProject) => buildProjectTasks(selectedProject),
    );
  }

  Widget buildSingleProjectView(Map<String, dynamic> project) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isTablet ? 28 : 20,
          right: isTablet ? 28 : 20,
          top: isTablet ? 28 : 20,
          bottom: isTablet ? 12 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: Colors.amber.shade700,
                  size: isTablet ? 28 : 24,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  'Active Project',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            projectView(context, project),
          ],
        ),
      ),
    );
  }

  Widget buildCurrentContracteeContainer([Map<String, dynamic>? project]) {
    final projectId = project?['project_id']?.toString() ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.amber[700],
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Current Contractee',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('Projects')
                  .stream(primaryKey: ['project_id'])
                  .map((rows) => rows.where((p) => p['project_id'] == projectId).toList()),
              builder: (context, _) {
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchCurrentContractee(projectId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading contractee',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      );
                    }

                    final contractee = snapshot.data;
                    
                    if (contractee == null) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No contractee assigned',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'A contractee will appear here.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return buildContracteeInfo(contractee);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContracteeInfo(Map<String, dynamic> project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey.shade200,
              child: (project['contractee_photo'] != null &&
                      project['contractee_photo'].toString().isNotEmpty)
                  ? Image.network(
                      project['contractee_photo'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image(
                          image: const AssetImage('assets/defaultpic.png'),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['full_name']?.toString() ?? "Client Name",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project['email'] != null && (project['email'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    project['email'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Navigate to chat history
              final router = GoRouter.of(context);
              router.go('/chathistory');
            },
            icon: Icon(
              Icons.message,
              color: Colors.amber[700],
              size: 24,
            ),
            tooltip: 'Open Chat History',
            style: IconButton.styleFrom(
              backgroundColor: Colors.amber.shade50,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileProjectsAndTasks() {
    return buildTabbedProjectView();
  }

  Widget buildDesktopStatsContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: buildStatCard(
                      'Active Projects',
                      activeProjects.toString(),
                      Icons.work,
                      Colors.black,
                      'Currently working on',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildStatCard(
                      'Completed',
                      completedProjects.toString(),
                      Icons.check_circle,
                      Colors.black,
                      'Successfully finished',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEarningsCard(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildStatCard(
                      'Number of Clients',
                      totalClients.toString(),
                      Icons.people,
                      Colors.black,
                      'Satisfied customers',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHiringRequestContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.request_page,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Hiring Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('Notifications')
                .stream(primaryKey: ['notification_id'])
                .map((rows) => rows),
            builder: (context, _) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: dashboardservice.fetchPendingHiringRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading hiring requests'));
                  }

                  final hiringRequests = snapshot.data ?? [];

                  if (hiringRequests.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hiring requests at the moment',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'New opportunities will appear here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    height: isMobile ? 240 : 300,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: hiringRequests.length,
                      itemBuilder: (context, index) {
                        final notification = hiringRequests[index];
                        return _buildCompactHiringCard(notification);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildWelcomeCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.shade400,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isTablet ? 50 : 40,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: contractorData?['profile_photo'] != null
                      ? Image.network(
                          contractorData!['profile_photo'],
                          width: (isTablet ? 50 : 40) * 2,
                          height: (isTablet ? 50 : 40) * 2,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image(
                              image: const AssetImage('assets/images/defaultpic.png'),
                              width: (isTablet ? 50 : 40) * 2,
                              height: (isTablet ? 50 : 40) * 2,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  size: isTablet ? 50 : 40,
                                  color: Colors.amber.shade700,
                                );
                              },
                            );
                          },
                        )
                      : Icon(
                          Icons.business,
                          size: isTablet ? 50 : 40,
                          color: Colors.amber.shade700,
                        ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 24 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contractorData?['firm_name'] ?? 'Contractor',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($completedProjects reviews)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProjectPhotoUrl(dynamic photoUrl) {
    if (photoUrl == null || photoUrl.toString().isEmpty) {
      return '';
    }
    final raw = photoUrl.toString();
    if (raw.startsWith('data:') || raw.startsWith('http')) {
      return raw;
    }
    try {
      return Supabase.instance.client.storage
          .from('projectphotos')
          .getPublicUrl(raw);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildCompactHiringCard(Map<String, dynamic> notification) {
    final info = notification['information'] as Map<String, dynamic>;
    final notificationId = notification['notification_id'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 18 : 20,
            child: ClipOval(
              child: Image.network(
                info['profile_photo'] != null && info['profile_photo'].isNotEmpty
                    ? info['profile_photo']
                    : 'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                width: (isMobile ? 18 : 20) * 2,
                height: (isMobile ? 18 : 20) * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image(
                    image: const AssetImage('assets/defaultpic.png'),
                    width: (isMobile ? 18 : 20) * 2,
                    height: (isMobile ? 18 : 20) * 2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: isMobile ? 18 : 20,
                        color: Colors.grey.shade400,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['project_title'] ?? 'Untitled Project',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'by ${info['full_name'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showProjectDetailsDialog(info),
                icon: Icon(Icons.info_outline, size: isMobile ? 18 : 20),
                tooltip: 'More Info',
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 28 : 32, 
                  minHeight: isMobile ? 28 : 32
                ),
              ),
              Builder(
                builder: (context) {
                  final status = (info['status'] as String? ?? 'pending').toLowerCase();
                  final isRejected = status == 'rejected' || status == 'declined' || status == 'cancelled';
                  final isAccepted = status == 'accepted';
                  if (isRejected || isAccepted) {
                    return Row(
                      children: [
                        SizedBox(width: isMobile ? 3 : 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAccepted ? Colors.green.shade600 : Colors.red.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAccepted ? 'ACCEPTED' : 'REJECTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  // Pending: show Decline and Accept
                  return Row(
                    children: [
                      SizedBox(width: isMobile ? 3 : 4),
                      IconButton(
                        onPressed: () => dashboardservice.handleDeclineHiring(
                          context: context,
                          notificationId: notificationId,
                        ),
                        icon: Icon(Icons.close, size: isMobile ? 16 : 18),
                        tooltip: 'Decline',
                        padding: EdgeInsets.all(isMobile ? 3 : 4),
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32, 
                          minHeight: isMobile ? 28 : 32
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade700,
                        ),
                      ),
                      SizedBox(width: isMobile ? 3 : 4),
                      IconButton(
                        onPressed: () => dashboardservice.handleAcceptHiring(
                          context: context,
                          notificationId: notificationId,
                          info: info,
                        ),
                        icon: Icon(Icons.check, size: isMobile ? 16 : 18),
                        tooltip: 'Accept',
                        padding: EdgeInsets.all(isMobile ? 3 : 4),
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32, 
                          minHeight: isMobile ? 28 : 32
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProjectDetailsDialog(Map<String, dynamic> info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1000;
        
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : 500,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Project Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                child: ClipOval(
                                  child: Image.network(
                                    info['profile_photo'] != null && info['profile_photo'].isNotEmpty
                                        ? info['profile_photo']
                                        : 'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image(
                                        image: const AssetImage('assets/images/defaultpic.png'),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey.shade400,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info['full_name'] ?? 'Unknown Client',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      info['email'] ?? 'No email provided',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (info['photo_url'] != null && info['photo_url'].toString().isNotEmpty) ...[
                            _buildProjectPhotoButton(info['photo_url']),
                            const SizedBox(height: 16),
                          ],
                          _buildDetailField('Project Title', info['project_title'] ?? 'Untitled Project', isDesktop),
                          _buildDetailField('Project Type', info['project_type'] ?? 'Not specified', isDesktop),
                          _buildDetailField('Location', info['project_location'] ?? 'Not specified', isDesktop),
                          _buildDetailField('Description', info['project_description'] ?? 'No description provided', isDesktop),
                          
                          if (info['min_budget'] != null && info['max_budget'] != null)
                            _buildDetailField('Budget Range', '₱${info['min_budget']} - ₱${info['max_budget']}', isDesktop)
                          else if (info['project_budget'] != null)
                            _buildDetailField('Budget', '₱${info['project_budget']}', isDesktop)
                          else
                            _buildDetailField('Budget', 'Not specified', isDesktop),
                          
                          if (info['start_date'] != null)
                            _buildDetailField('Preferred Start Date', info['start_date'].toString().split(' ')[0], isDesktop),
                          
                          if (info['additional_info'] != null && info['additional_info'].isNotEmpty)
                            _buildDetailField('Additional Information', info['additional_info'], isDesktop),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailField(String label, String value, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final double maxWidth = size.width * 0.75;
        final double maxHeight = size.height * 0.7;

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectPhotoButton(dynamic photoUrl) {
    final photoUrlString = _getProjectPhotoUrl(photoUrl);
    if (photoUrlString.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    'Project Photo:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFullPhoto(photoUrlString),
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('View Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Photo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFullPhoto(photoUrlString),
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('View Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildStatsGrid() {
    if (isDesktop) {
      return const SizedBox.shrink();
    }

    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 2.5;
      spacing = 16;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 1.1;
      spacing = 12;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            children: [
              buildStatCard(
                'Active Projects',
                activeProjects.toString(),
                Icons.work,
                Colors.black,
                'Currently working on',
              ),
              buildStatCard(
                'Completed',
                completedProjects.toString(),
                Icons.check_circle,
                Colors.black,
                'Successfully finished',
              ),
              _buildEarningsCard(),
              buildStatCard(
                'Number of Clients',
                totalClients.toString(),
                Icons.people,
                Colors.black,
                'Satisfied customers',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 900 && screenWidth < 1200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isDesktop ? 20 : (isTablet ? 10 : 12),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 15.2 : (isTablet ? 14 : 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isDesktop ? 14 : (isTablet ? 14 : 12),
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isDesktop ? 12 : (isTablet ? 16 : 8),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isDesktop ? 22 : (isTablet ? 22 : 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 23 : (isTablet ? 20 : 8)),
            Text(
              value,
              style: TextStyle(
                fontSize: isDesktop ? 17 : (isTablet ? 15 : 18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecentProjects() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: Colors.amber.shade700,
                  size: isTablet ? 28 : 24,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  'Active Projects',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            ..._getProjectsToShow().map(
              (project) => projectView(context, project),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProjectTasks([Map<String, dynamic>? project]) {
    final projectData = project ?? (recentActivities.isNotEmpty ? recentActivities.first : null);
    final projectId = projectData?['project_id']?.toString() ?? '';
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: Colors.green.shade700,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Project Tasks',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            if (projectId.isEmpty)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 30 : (isTablet ? 40 : 30),
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: isDesktop ? 40 : (isTablet ? 48 : 32),
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: isDesktop ? 12 : (isTablet ? 16 : 8)),
                      Text(
                        'No project selected',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : (isTablet ? 18 : 12),
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('ProjectTasks')
                    .stream(primaryKey: ['task_id'])
                    .eq('project_id', projectId)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.amber),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading tasks',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  final tasks = snapshot.data ?? [];
                  
                  if (tasks.isEmpty) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 30 : (isTablet ? 40 : 30),
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: isDesktop ? 40 : (isTablet ? 48 : 32),
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: isDesktop ? 12 : (isTablet ? 16 : 8)),
                            Text(
                              'No tasks yet',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : (isTablet ? 18 : 12),
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tasks will appear here when added',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Always show only 3 tasks
                  final tasksToShow = tasks.take(3).toList();
                  final hasMoreTasks = tasks.length > 3;
                  
                  return Column(
                    children: [
                      ...tasksToShow.map(
                        (task) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (task['done'] == true || task['task_done'] == true)
                                  ? Colors.green.shade200
                                  : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                (task['done'] == true || task['task_done'] == true)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: (task['done'] == true || task['task_done'] == true)
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['task']?.toString() ?? 'Untitled Task',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        decoration: (task['done'] == true || task['task_done'] == true)
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: (task['done'] == true || task['task_done'] == true)
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade800,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (task['expect_finish'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due: ${_formatTaskDate(task['expect_finish'])}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasMoreTasks)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                if (projectId.isNotEmpty) {
                                  context.go('/project-management/$projectId');
                                }
                              },
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text(
                                'View ${tasks.length - 3} more task${tasks.length - 3 > 1 ? 's' : ''} in Project Management',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTaskDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';
    try {
      final date = DateTime.parse(dateValue.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  List<Map<String, dynamic>> _getProjectsToShow() {
    if (recentActivities.isEmpty) {
      return [_getPlaceholderProject()];
    }
    return recentActivities;
  }

  Future<void> _showContractDialog(BuildContext context, String contractId) async {
    try {
      final contractor = Supabase.instance.client.auth.currentUser?.id ?? '';
      Map<String, dynamic> contractData = await ViewContractService.loadContract(contractId, contractorId: contractor);
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          Map<String, dynamic> liveData = contractData;
          return StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 900,
                      maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  liveData['title'] ?? 'Contract Details',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<String?>(
                                  future: ViewContractService.getPdfSignedUrl(liveData),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return ViewContractBuild.buildLoadingState();
                                    }
                                    if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
                                      return ViewContractBuild.buildPdfViewer(
                                        pdfUrl: null,
                                        onDownload: () => ViewContractService.handleDownload(
                                          contractData: liveData,
                                          context: context,
                                        ),
                                        height: 400,
                                      );
                                    }
                                    return ViewContractBuild.buildPdfViewer(
                                      pdfUrl: snapshot.data,
                                      onDownload: () => ViewContractService.handleDownload(
                                        contractData: liveData,
                                        context: context,
                                      ),
                                      height: 400,
                                      isSignedContract: (liveData['signed_pdf_url'] as String?)?.isNotEmpty == true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                ViewContractBuild.buildEnhancedSignaturesSection(
                                  liveData,
                                  onRefresh: () async {
                                    try {
                                      final updatedData = await ViewContractService.loadContract(contractId, contractorId: contractor);
                                      setState(() {
                                        liveData = updatedData;
                                      });
                                    } catch (e) {
                                      if (dialogContext.mounted) {
                                        ConTrustSnackBar.error(dialogContext, 'Failed to refresh: $e');
                                      }
                                    }
                                  },
                                  currentUserId: Supabase.instance.client.auth.currentUser?.id,
                                  context: dialogContext,
                                  contractStatus: liveData['status'] as String?,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error loading contract: $e');
      }
    }
  }
  Map<String, dynamic> _getPlaceholderProject() {
    return {
      'title': 'N/A',
      'description': 'You have no active projects at the moment.',
      'type': 'N/A',
      'contractee_name': 'No Contractee',
      'contractee_photo': null,
      'status': 'inactive',
      'isPlaceholder': true,
    };
  }

  Widget projectView(BuildContext context, Map<String, dynamic> project) {
    final projectId = project['project_id']?.toString() ?? '';
    
    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectHeader(context, project),
            
            const SizedBox(height: 16),
            _buildProjectDetails(project),
            
            const SizedBox(height: 16),
            _buildProjectDescription(project),
            
            if (project['status'] == 'cancellation_requested_by_contractee') ...[
              const SizedBox(height: 16),
              _buildCancellationRequestCard(
                project['information']?['cancellation_reason'] ?? 'No reason provided', 
                projectId
              ),
            ],
          ],
        ),
      ),
    );
    
    return card;
  }

  Widget _buildProjectHeader(BuildContext context, Map<String, dynamic> project) {
    final projectId = project['project_id']?.toString() ?? '';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project['title'] ?? 'No title given',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildStatusChip(project),
            ],
          ),
        ),
        Row(
          children: [
            _buildContractButton(context, projectId),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> project) {
    final statusColor = status.getStatusColor(project['status']);
    final statusLabel = status.getStatusLabel(project['status']);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(project['status']),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails(Map<String, dynamic> project) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    
    final details = [
      _buildDetailItem(
        icon: Icons.money,
        label: 'BUDGET',
        value: _formatProjectBudget(project),
      ),
      _buildDetailItem(
        icon: Icons.calendar_today,
        label: 'START DATE',
        value: _formatProjectStartDate(project),
      ),
      _buildDetailItem(
        icon: Icons.location_on,
        label: 'LOCATION',
        value: project['location'] ?? 'Not specified',
      ),
      if (project['type'] != null)
        _buildDetailItem(
          icon: Icons.category,
          label: 'TYPE',
          value: project['type'],
        ),
    ];

    // If screen width > 1200, show labels in two columns
    if (isWideScreen) {
      return Column(
        children: [
          for (int i = 0; i < details.length; i += 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details[i]),
                  if (i + 1 < details.length)
                    const SizedBox(width: 16),
                  if (i + 1 < details.length)
                    Expanded(child: details[i + 1]),
                ],
              ),
            ),
        ],
      );
    }

    // Otherwise, show all labels in one column
    return Column(
      children: [
        for (int i = 0; i < details.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: details[i],
          ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: isDesktop
              ? RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Text(
                      '$label: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildProjectDescription(Map<String, dynamic> project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          project['description'] ?? 'No description provided',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContractButton(BuildContext context, String projectId) {
    if (projectId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'No Contract',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FetchService().streamContractsForProject(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'No Contract',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final contracts = snapshot.data!;
        final latestContract = contracts.first;
        final status = latestContract['status'] as String? ?? 'draft';
        
        Color borderColor;
        Color backgroundColor;
        Color textColor;
        IconData icon;
        String statusText;

        switch (status.toLowerCase()) {
          case 'approved':
          case 'active':
          case 'signed':
            borderColor = Colors.green.shade600;
            backgroundColor = Colors.green.shade50;
            textColor = Colors.green.shade700;
            icon = Icons.verified;
            statusText = 'Contract Accepted';
            break;
          case 'sent':
            borderColor = Colors.orange.shade600;
            backgroundColor = Colors.orange.shade50;
            textColor = Colors.orange.shade700;
            icon = Icons.pending;
            statusText = 'Contract Waiting for approval';
            break;
          case 'awaiting_signature':
            borderColor = Colors.orange.shade600;
            backgroundColor = Colors.orange.shade50;
            textColor = Colors.orange.shade700;
            icon = Icons.pending;
            statusText = 'Contract Awaiting Signature';
            break;
          case 'rejected':
            borderColor = Colors.red.shade600;
            backgroundColor = Colors.red.shade50;
            textColor = Colors.red.shade700;
            icon = Icons.cancel;
            statusText = 'Contract Rejected';
            break;
          default:
            borderColor = Colors.blue.shade600;
            backgroundColor = Colors.blue.shade50;
            textColor = Colors.blue.shade700;
            icon = Icons.description;
            statusText = 'Contract Draft';
        }

        return InkWell(
          onTap: () => _showContractDialog(context, latestContract['contract_id'] as String),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.visibility, size: 14, color: textColor),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatProjectBudget(Map<String, dynamic> project) {
    return "₱${project['min_budget']?.toString() ?? '0'} - ₱${project['max_budget']?.toString() ?? '0'}";
  }

  String _formatProjectStartDate(Map<String, dynamic> project) {
    if (project['start_date'] == null) return 'Not specified';
    
    try {
      final date = DateTime.parse(project['start_date']);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_circle_filled;
      case 'pending':
        return Icons.pending;
      case 'awaiting_contract':
        return Icons.description;
      case 'awaiting_agreement':
        return Icons.handshake;
      case 'awaiting_signature':
        return Icons.edit;
      case 'cancellation_requested_by_contractee':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.verified;
      case 'stopped':
        return Icons.stop_circle;
      case 'closed':
        return Icons.lock;
      case 'rejected':
        return Icons.thumb_down;
      case 'draft':
        return Icons.edit;
      default:
        return Icons.help;
    }
  }

  Widget _buildCancellationRequestCard(String reason, String projectId) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Cancellation Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Reason: $reason',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'The contractee has requested to cancel this project. Please choose your response:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleCancellationResponse(projectId, false),
                  icon: Icon(Icons.close, size: 18),
                  label: Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleCancellationResponse(projectId, true),
                  icon: Icon(Icons.check, size: 18),
                  label: Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancellationResponse(String projectId, bool approve) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        ConTrustSnackBar.error(context, 'User not authenticated');
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(approve ? 'Approve Cancellation' : 'Reject Cancellation'),
          content: Text(
            approve 
              ? 'Are you sure you want to approve this cancellation request? This will permanently cancel the project.'
              : 'Are you sure you want to reject this cancellation request? The project will continue.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(approve ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      );

      if (confirmed == true) {

        try {
          if (approve) {
            await ProjectService().agreeCancelAgreement(projectId, currentUserId);
          } else {
            await ProjectService().declineCancelAgreement(projectId, currentUserId);
          }

          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (context.mounted) {
            ConTrustSnackBar.success(
              context, 
              approve 
                ? 'Cancellation approved. Project has been cancelled.' 
                : 'Cancellation rejected. Project will continue.'
            );
          }
          

          await Future.delayed(Duration(milliseconds: 500));
          if (onDataRefresh != null && context.mounted) {
            onDataRefresh!();
          }
          
        } catch (e) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (context.mounted) {
            ConTrustSnackBar.error(context, 'Error processing cancellation response: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Error processing cancellation response: $e');
      }
    }
  }


  Future<Map<String, dynamic>?> _fetchCurrentContractee(String projectId) async {
    try {
      if (projectId.isEmpty) return null;
      
      final supabase = Supabase.instance.client;
      
      // First, fetch the project to get contractee_id
      final projectResponse = await supabase
          .from('Projects')
          .select('contractee_id')
          .eq('project_id', projectId)
          .maybeSingle();
      
      if (projectResponse == null) return null;
      
      final contracteeId = projectResponse['contractee_id'] as String?;
      if (contracteeId == null || contracteeId.isEmpty) return null;
      
      // Fetch contractee data
      final contracteeResponse = await supabase
          .from('Contractee')
          .select('contractee_id, full_name, profile_photo')
          .eq('contractee_id', contracteeId)
          .maybeSingle();
      
      if (contracteeResponse == null) return null;
      
      String email = '';
      try {
        final userData = await supabase
            .from('Users')
            .select('email')
            .eq('users_id', contracteeId)
            .maybeSingle();
        if (userData != null) {
          email = userData['email'] ?? '';
        }
      } catch (_) {
        //
      }
      
      return {
        'contractee_id': contracteeResponse['contractee_id'],
        'full_name': contracteeResponse['full_name'],
        'contractee_photo': contracteeResponse['profile_photo'],
        'email': email,
      };
    } catch (e) {
      return null;
    }
  }

  Widget _buildEarningsCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 900 && screenWidth < 1200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isDesktop ? 20 : (isTablet ? 10 : 12),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 15.2 : (isTablet ? 14 : 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isDesktop ? 14 : (isTablet ? 14 : 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isDesktop ? 12 : (isTablet ? 16 : 8),
                    ),
                  ),
                  child: Icon(
                    Icons.money,
                    color: Colors.black,
                    size: isDesktop ? 22 : (isTablet ? 22 : 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 23 : (isTablet ? 20 : 8)),
            Text(
              '₱${totalEarnings.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isDesktop ? 17 : (isTablet ? 15 : 18),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total Earning',
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'From all projects',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:backend/services/contractor services/cor_dashboardservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:flutter/material.dart';

class DashboardBuildMethods {
  DashboardBuildMethods(
    this.context,
    this.recentActivities,
    this.activeProjects,
    this.completedProjects,
    this.totalEarnings,
    this.totalClients,
    this.rating,
  );

  final BuildContext context;
  final ProjectStatus status = ProjectStatus();
  final CorDashboardService dashboardservice = CorDashboardService();

  List<Map<String, dynamic>> recentActivities = [];
  List<Map<String, dynamic>> localTasks = [];
  Map<String, dynamic>? contractorData;

  int activeProjects = 0;
  int completedProjects = 0;
  double totalEarnings = 0.0;
  int totalClients = 0;
  double rating = 0.0;

  double get screenWidth => MediaQuery.of(context).size.width;
  bool get isDesktop => screenWidth >= 1200;
  bool get isTablet => screenWidth >= 700 && screenWidth < 1200;
  bool get isMobile => screenWidth < 700;

  Widget buildDesktopProjectsAndTasks() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              buildWelcomeCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: buildStatCard(
                      'Completed',
                      completedProjects.toString(),
                      Icons.check_circle,
                      Colors.black,
                      'Successfully finished',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildStatCard(
                      'Total Earnings',
                      '₱${totalEarnings.toStringAsFixed(0)}',
                      Icons.money,
                      Colors.black,
                      'From all projects',
                    ),
                  ),
                  const SizedBox(width: 16),
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
              const SizedBox(height: 20),
              buildRecentProjects(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              buildCurrentContracteeContainer(),
              const SizedBox(height: 20),
              buildProjectTasks(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCurrentContracteeContainer() {
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
                  color: Colors.blue.shade700,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Current Contractee',
                  style: TextStyle(
                    fontSize: screenWidth * 0.01,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            buildContracteeInfo(_getContracteeToShow()),
          ],
        ),
      ),
    );
  }

  Widget buildContracteeInfo(Map<String, dynamic> project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                backgroundImage:
                    project['contractee_photo'] != null &&
                            project['contractee_photo'].toString().isNotEmpty
                        ? NetworkImage(project['contractee_photo'])
                        : null,
                child:
                    project['contractee_photo'] == null ||
                            project['contractee_photo'].toString().isEmpty
                        ? Icon(
                          Icons.person,
                          color: Colors.blue.shade700,
                          size: 20,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['contractee_name']?.toString() ?? "Client Name",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      project['title']?.toString() ?? 'No Project Title',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.getStatusColor(project['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.getStatusLabel(project['status']),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status.getStatusColor(project['status']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMobileProjectsAndTasks() {
    return Column(
      children: [
        buildRecentProjects(),
        const SizedBox(height: 20),
        buildProjectTasks(),
      ],
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
                backgroundImage:
                    contractorData?['profile_photo'] != null
                        ? NetworkImage(contractorData!['profile_photo'])
                        : null,
                child:
                    contractorData?['profile_photo'] == null
                        ? Icon(
                          Icons.business,
                          size: isTablet ? 50 : 40,
                          color: Colors.amber.shade700,
                        )
                        : null,
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
      childAspectRatio = 1.3;
      spacing = 12;
    }

    return GridView.count(
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
        buildStatCard(
          'Total Earnings',
          '₱${totalEarnings.toStringAsFixed(0)}',
          Icons.money,
          Colors.black,
          'From all projects',
        ),
        buildStatCard(
          'Number of Clients',
          totalClients.toString(),
          Icons.people,
          Colors.black,
          'Satisfied customers',
        ),
      ],
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

  Widget buildProjectTasks() {
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
            SizedBox(height: isTablet ? 16 : 12),
            if (localTasks.isEmpty)
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
                        'No tasks yet',
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
            else ...[
              ...localTasks
                  .take(isDesktop ? 2 : 3)
                  .map(
                    (task) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            task['done'] == true
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color:
                                task['done'] == true
                                    ? Colors.green
                                    : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task['task'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                decoration:
                                    task['done'] == true
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (localTasks.length > (isDesktop ? 2 : 3))
                Center(
                  child: Text(
                    '+${localTasks.length - (isDesktop ? 2 : 3)} more tasks...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getProjectsToShow() {
    if (recentActivities.isEmpty) {
      return [_getPlaceholderProject()];
    }
    return recentActivities;
  }

  Map<String, dynamic> _getContracteeToShow() {
    if (recentActivities.isEmpty) {
      return _getPlaceholderContractee();
    }
    return recentActivities.first;
  }

  Map<String, dynamic> _getPlaceholderContractee() {
    return {
      'contractee_name': 'No Contractee',
      'contractee_photo': null,
      'title': 'No Active Project',
      'status': 'inactive',
    };
  }

  Map<String, dynamic> _getPlaceholderProject() {
    return {
      'title': 'No Active Projects',
      'description': 'You have no active projects at the moment.',
      'type': 'N/A',
      'contractee_name': 'No Contractee',
      'contractee_photo': null,
      'status': 'inactive',
      'isPlaceholder': true,
    };
  }

  Widget projectView(BuildContext context, Map<String, dynamic> project) {
    bool isPlaceholder = project['isPlaceholder'] == true;
    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project['title'] ?? 'No title given',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Description: ${project['description'] ?? 'No description'}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'Type: ${project['type'] ?? 'No type'}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status.getStatusColor(
                      project['status'],
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Status: ${status.getStatusLabel(project['status'])}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: status.getStatusColor(project['status']),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (isPlaceholder) {
      return card;
    } else {
      return InkWell(
        onTap: () => dashboardservice.navigateToProject(
          context: context,
          project: project,
          onNavigate: () {},
        ),
        child: card,
      );
    }
  }
}
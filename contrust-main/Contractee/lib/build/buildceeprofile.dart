// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class CeeProfileBuildMethods {
  static Widget buildMainContent(String selectedTab, Function buildProjectsContent, Function buildAboutContent, Function buildHistoryContent) {
    switch (selectedTab) {
      case 'Projects':
        return buildProjectsContent();
      case 'About':
        return buildAboutContent();
      case 'History':
        return buildHistoryContent();
      default:
        return buildProjectsContent();
    }
  }

  static Widget buildMobileLayout({
    required String firstName,
    required String lastName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade200, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                        ? NetworkImage(profileImage)
                        : NetworkImage(profileUrl),
                    child: (profileImage == null || profileImage.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Homeowner',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade100, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(ongoingProjectsCount, 'Ongoing', Colors.amber.shade700, Icons.work_outline),
                      Container(width: 1, height: 35, color: Colors.grey.shade200),
                      _buildStatItem(completedProjectsCount, 'Completed', Colors.grey.shade600, Icons.check_circle_outline),
                      Container(width: 1, height: 35, color: Colors.grey.shade200),
                      _buildStatItem(ongoingProjectsCount + completedProjectsCount, 'Total', Colors.grey.shade700, Icons.folder_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: buildMobileNavigation(selectedTab, onTabChanged),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: mainContent,
        ),
      ],
    );
  }

  static Widget buildDesktopLayout({
    required String firstName,
    required String lastName,
    required String? profileImage,
    required String profileUrl,
    required int completedProjectsCount,
    required int ongoingProjectsCount,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget mainContent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.shade200, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                              ? NetworkImage(profileImage)
                              : NetworkImage(profileUrl),
                          child: (profileImage == null || profileImage.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 42,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Homeowner',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade100, width: 2),
                        ),
                        child: Column(
                          children: [
                            _buildStatItem(ongoingProjectsCount, 'Ongoing', Colors.amber.shade700, Icons.work_outline),
                            const SizedBox(height: 16),
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            _buildStatItem(completedProjectsCount, 'Completed', Colors.grey.shade600, Icons.check_circle_outline),
                            const SizedBox(height: 16),
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            _buildStatItem(ongoingProjectsCount + completedProjectsCount, 'Total', Colors.grey.shade700, Icons.folder_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      buildNavigation('Projects', selectedTab == 'Projects', () => onTabChanged('Projects'), Icons.work_outline),
                      const SizedBox(height: 4),
                      buildNavigation('About', selectedTab == 'About', () => onTabChanged('About'), Icons.info_outline),
                      const SizedBox(height: 4),
                      buildNavigation('History', selectedTab == 'History', () => onTabChanged('History'), Icons.history),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SingleChildScrollView(
              child: mainContent,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildProjects({
    required List<Map<String, dynamic>> ongoingProjects,
    required Function getTimeAgo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ongoing Projects',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ongoingProjects.length} active project${ongoingProjects.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        if (ongoingProjects.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.work_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Ongoing Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a new project to see it here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ongoingProjects.length,
            itemBuilder: (context, index) {
              final project = ongoingProjects[index];
              final projectName = project['project_name'] ?? 'Unnamed Project';
              final contractorName = project['contractor_name'] ?? 'No Contractor';
              final startDate = project['start_date'] != null
                  ? DateTime.parse(project['start_date'])
                  : DateTime.now();
              final timeAgo = getTimeAgo(startDate);
              
              return buildProjectCard(
                projectName,
                contractorName,
                'Ongoing',
                Colors.blue,
                timeAgo,
                Icons.construction,
              );
            },
          ),
      ],
    );
  }

  static Widget buildAbout({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String bio,
    required String contactNumber,
    required String address,
    required bool isEditingFirstName,
    required bool isEditingLastName,
    required bool isEditingBio,
    required bool isEditingContact,
    required bool isEditingAddress,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController bioController,
    required TextEditingController contactController,
    required TextEditingController addressController,
    required VoidCallback toggleEditFirstName,
    required VoidCallback toggleEditLastName,
    required VoidCallback toggleEditBio,
    required VoidCallback toggleEditContact,
    required VoidCallback toggleEditAddress,
    required VoidCallback saveFirstName,
    required VoidCallback saveLastName,
    required VoidCallback saveBio,
    required VoidCallback saveContact,
    required VoidCallback saveAddress,
    required String contracteeId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 32),
            
            buildContracteeInfo(
              'First Name',
              firstName,
              Icons.person,
              Colors.amber.shade700,
              isEditingFirstName,
              firstNameController,
              toggleEditFirstName,
              saveFirstName,
            ),
            const SizedBox(height: 24),
            
            buildContracteeInfo(
              'Last Name',
              lastName,
              Icons.person_outline,
              Colors.amber.shade700,
              isEditingLastName,
              lastNameController,
              toggleEditLastName,
              saveLastName,
            ),
            const SizedBox(height: 24),
            
            buildContracteeInfo(
              'Bio',
              bio,
              Icons.description,
              Colors.amber.shade700,
              isEditingBio,
              bioController,
              toggleEditBio,
              saveBio,
            ),
            const SizedBox(height: 24),
            
            buildContracteeInfo(
              'Contact Information',
              contactNumber,
              Icons.phone,
              Colors.amber.shade700,
              isEditingContact,
              contactController,
              toggleEditContact,
              saveContact,
            ),
            const SizedBox(height: 24),
            
            buildContracteeInfo(
              'Address',
              address,
              Icons.location_on,
              Colors.amber.shade700,
              isEditingAddress,
              addressController,
              toggleEditAddress,
              saveAddress,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildHistory({
    required List<Map<String, dynamic>> projectHistory,
    required Function getTimeAgo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Project History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            if (projectHistory.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Project History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete projects to see them in your history',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectHistory.length,
                itemBuilder: (context, index) {
                  final project = projectHistory[index];
                  final projectName = project['project_name'] ?? 'Unnamed Project';
                  final contractorName = project['contractor_name'] ?? 'No Contractor';
                  final completionDate = project['completion_date'] != null
                      ? DateTime.parse(project['completion_date'])
                      : DateTime.now();
                  final timeAgo = getTimeAgo(completionDate);
                  
                  return buildProjectCard(
                    projectName,
                    contractorName,
                    'Completed',
                    Colors.green,
                    timeAgo,
                    Icons.check_circle,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildProjectCard(String projectName, String contractorName, String status, Color statusColor, String timeAgo, IconData statusIcon) {
    // Use amber for ongoing, grey for completed
    final isOngoing = status == 'Ongoing';
    final displayColor = isOngoing ? Colors.amber.shade700 : Colors.grey.shade600;
    final bgColor = isOngoing ? Colors.amber.shade50 : Colors.grey.shade50;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusIcon,
                color: displayColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contractorName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: displayColor.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: displayColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildNavigation(String title, bool isActive, VoidCallback onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.amber.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.amber.shade900 : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.amber.shade700,
              ),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildStatItem(int count, String label, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  static Widget buildMobileNavigation(String selectedTab, Function(String) onTabChanged) {
    final tabs = ['Projects', 'About', 'History'];
    
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = selectedTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ] : [],
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.amber.shade900 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget buildContracteeInfo(
    String title,
    String content,
    IconData icon,
    Color color,
    bool isEditing,
    TextEditingController controller,
    VoidCallback onEdit,
    VoidCallback onSave,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              if (isEditing)
                Row(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onSave,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEditing)
            TextField(
              controller: controller,
              maxLines: title == 'Bio' ? 3 : 1,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                height: 1.5,
              ),
            )
          else
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
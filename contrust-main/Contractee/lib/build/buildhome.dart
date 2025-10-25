// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_UIapp.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageBuilder {
  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  static Widget buildStatsSection({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> contractors,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.amber[700], size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  "Platform Statistics",
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          isMobile
            ? Column(
                children: [
                  _buildStatCard(
                    "Active Projects",
                    "${projects.where((p) => p['status'] == 'active').length}",
                    Icons.work,
                    Colors.black,
                    isMobile,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    "Pending Projects",
                    "${projects.where((p) => p['status'] == 'pending').length}",
                    Icons.pending,
                    Colors.black,
                    isMobile,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    "Completed",
                    "${projects.where((p) => p['status'] == 'ended').length}",
                    Icons.check_circle,
                    Colors.black,
                    isMobile,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Active Projects",
                      "${projects.where((p) => p['status'] == 'active').length}",
                      Icons.work,
                      Colors.black,
                      isMobile,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Pending Projects",
                      "${projects.where((p) => p['status'] == 'pending').length}",
                      Icons.pending,
                      Colors.black,
                      isMobile,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Completed",
                      "${projects.where((p) => p['status'] == 'ended').length}",
                      Icons.check_circle,
                      Colors.black,
                      isMobile,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  static Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : null,
      padding: EdgeInsets.all(isMobile ? 12 : 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isMobile
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
    );
  }

  static Widget buildEmptyProjectsPlaceholder({
    required BuildContext context,
    required SupabaseClient supabase,
    VoidCallback? onPostProject,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 80,
            color: Colors.amber[700],
          ),
          const SizedBox(height: 20),
          Text(
            "No Projects Yet",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Start your construction journey by posting your first project and connecting with skilled contractors.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Map<String, dynamic> getPlaceholderProject() {
    return {
      'title': 'No Projects Yet',
      'description': 'You have no active projects at the moment. Start by posting your first project.',
      'type': 'N/A',
      'contractee_name': 'You',
      'contractee_photo': null,
      'status': 'inactive',
      'isPlaceholder': true,
    };
  }

  static List<Map<String, dynamic>> getProjectsToShow(List<Map<String, dynamic>> projects) {
    if (projects.isEmpty) {
      return [getPlaceholderProject()];
    }
    return projects;
  }

  static Widget buildProjectsSection({
    required BuildContext context,
    required List<Map<String, dynamic>> projects,
    required SupabaseClient supabase,
    VoidCallback? onPostProject,
  }) {
    final projectsToShow = getProjectsToShow(projects);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, color: Colors.amber[700], size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                "Your Projects",
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          ...projectsToShow.map((project) => _buildProjectCard(context, project, supabase)),
        ],
      ),
    );
  }

  static Widget _buildProjectCard(BuildContext context, Map<String, dynamic> project, SupabaseClient supabase) {
    bool isPlaceholder = project['isPlaceholder'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isPlaceholder ? null : () {
          final projectStatus = project['status']?.toString().toLowerCase();
          if (projectStatus != 'active') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Project is not active yet. Current status: ${projectStatus ?? 'Unknown'}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project['title'] ?? 'No title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project['description'] ?? 'No description',
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Type: ${project['type'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPlaceholder ? Colors.grey.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPlaceholder ? 'Placeholder' : 'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPlaceholder ? Colors.grey : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildNoContractorsPlaceholder(TextEditingController searchController) {
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "No contractors yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    ),
  );
}


  static Widget buildContractorsSection({
    required BuildContext context,
    required bool isLoading,
    required List<Map<String, dynamic>> filteredContractors,
    required TextEditingController searchController,
    required int selectedIndex,
    required Function(int) onSelect,
    required String profileUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                "Suggested Contractor Firms",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.90,
              height: 50,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search contractors...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber, width: 2.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 280,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredContractors.isEmpty
                    ? buildNoContractorsPlaceholder(searchController)
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredContractors.length,
                        itemBuilder: (context, index) {
                          final contractor = filteredContractors[index];
                          final profilePhoto = contractor['profile_photo'];
                          final profileImage =
                              (profilePhoto == null || profilePhoto.isEmpty)
                                  ? profileUrl
                                  : profilePhoto;
                          final isSelected = selectedIndex == index;
                          return GestureDetector(
                            onTap: () {
                              onSelect(index);
                            },
                            child: Container(
                              width: 200,
                              height: 250,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? const Color.fromARGB(255, 99, 98, 98)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ContractorsView(
                                id: contractor['contractor_id'] ?? '',
                                name: contractor['firm_name'] ?? 'Unknown',
                                profileImage: profileImage,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

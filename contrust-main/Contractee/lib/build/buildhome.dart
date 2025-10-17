// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageBuilder {
  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  static Widget buildStatsSection({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> contractors,
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
              Icon(Icons.analytics, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              Text(
                "Platform Statistics",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Active Projects",
                  "${projects.where((p) => p['status'] == 'active').length}",
                  Icons.work,
                  Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Pending Projects",
                  "${projects.where((p) => p['status'] == 'pending').length}",
                  Icons.pending,
                  Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Completed",
                  "${projects.where((p) => p['status'] == 'ended').length}",
                  Icons.check_circle,
                  Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
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
              Icon(Icons.work_outline, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              Text(
                "Your Projects",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onPostProject,
                icon: const Icon(Icons.add),
                label: const Text('Post Your Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
}

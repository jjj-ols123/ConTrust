// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_UIapp.dart';
import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_message_service.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageBuilder {
  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  static Widget buildStatsSection({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> contractors,
    required BuildContext context,
    VoidCallback? onCompletedProjectsClick,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    final completedCount = projects
        .where((project) {
          final status = (project['status']?.toString().toLowerCase() ?? '');
          return status == 'completed' || status == 'ended';
        })
        .length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
              Icon(Icons.bar_chart, color: Colors.amber, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  "Statistics",
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          isMobile
            ? _buildStatCard(
                "Completed Projects",
                "$completedCount",
                Icons.check_circle,
                Colors.grey.shade600,
                isMobile,
                subtitle: 'Successfully finished',
                onTap: completedCount > 0
                    ? (onCompletedProjectsClick ?? () => showCompletedProjectsSelector(context))
                    : null,
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Completed Projects",
                      "$completedCount",
                      Icons.check_circle,
                      Colors.black,
                      isMobile,
                      subtitle: 'Successfully finished',
                      onTap: completedCount > 0
                          ? (onCompletedProjectsClick ?? () => showCompletedProjectsSelector(context))
                          : null,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  static Future<void> _handleMessageTap(BuildContext context, Map<String, dynamic> bid) async {
    final contracteeId = Supabase.instance.client.auth.currentUser?.id;
    if (contracteeId == null) {
      ConTrustSnackBar.warning(context, 'Please sign in again to start a chat.');
      return;
    }

    final contractorId = bid['contractor_id']?.toString();
    final projectId = bid['project_id']?.toString();
    if (contractorId == null || contractorId.isEmpty || projectId == null || projectId.isEmpty) {
      ConTrustSnackBar.error(context, 'Missing contractor or project information.');
      return;
    }

    final contractorData = bid['contractor'] as Map<String, dynamic>?;
    final contractorName = contractorData?['firm_name']?.toString() ?? 'Contractor';
    final contractorProfile = contractorData?['profile_photo'];

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );

    String? chatRoomId;
    try {
      chatRoomId = await MessageService().getOrCreateChatRoom(
        contractorId: contractorId,
        contracteeId: contracteeId,
        projectId: projectId,
      );
    } catch (e) {
      chatRoomId = null;
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Failed to start chat: $e');
      }
    } finally {
      if (navigator.mounted && navigator.canPop()) {
        navigator.pop();
      }
    }

    if (chatRoomId == null) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Unable to start chat. Please try again.');
      }
      return;
    }

    if (!context.mounted) return;

    final encodedName = Uri.encodeComponent(contractorName);
    context.go(
      '/chat/$encodedName',
      extra: {
        'chatRoomId': chatRoomId,
        'contracteeId': contracteeId,
        'contractorId': contractorId,
        'contractorProfile': contractorProfile,
      },
    );
  }

  static Future<void> showCompletedProjectsSelector(BuildContext context) async {
    try {
      final contracteeId = Supabase.instance.client.auth.currentUser?.id;
      if (contracteeId == null) {
        ConTrustSnackBar.warning(context, 'Please sign in again.');
        return;
      }

      // Fetch all projects for the contractee
      final allProjects = await FetchService().fetchUserProjects();

      // Filter for completed projects (status = 'ended')
      final completedProjects = allProjects
          .where((project) {
            final status = (project['status']?.toString().toLowerCase() ?? '');
            return status == 'completed' || status == 'ended';
          })
          .toList();

      if (completedProjects.isEmpty) {
        ConTrustSnackBar.info(context, 'No completed projects found.');
        return;
      }

      final selectedProjectId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                      color: Colors.amber, 
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
                            Icons.check_circle, // Check circle icon for completed
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Completed Projects',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: completedProjects.length,
                        itemBuilder: (context, index) {
                          final project = completedProjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                project['title'] ?? 'Untitled Project',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              subtitle: Text('Status: Completed'),
                              leading: Icon(Icons.check_circle, color: Colors.green.shade700),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green.shade700),
                              onTap: () {
                                Navigator.of(dialogContext).pop(project['project_id']);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
        if (!context.mounted) return;
        context.go('/ongoing/$selectedProjectId');
      }
    } catch (e) {
      if (context.mounted) {
        ConTrustSnackBar.error(context, 'Failed to load completed projects');
      }
    }
  }

  static Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final double padding = isMobile ? 12 : 16;
    final double iconPadding = isMobile ? 12 : 14;
    final double valueFontSize = isMobile ? 22 : 20;
    final double titleFontSize = isMobile ? 14 : 16;
    final double subtitleFontSize = isMobile ? 12 : 13;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: isMobile
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(iconPadding),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (subtitle != null && subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    SizedBox(height: 16),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  static Widget buildEmptyProjectsPlaceholder({
    required BuildContext context,
    required SupabaseClient supabase,
    VoidCallback? onPostProject,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
            size: 56,
            color: Colors.amber[700],
          ),
          const SizedBox(height: 16),
          Text(
            "No Projects Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start your construction journey by posting your first project and connecting with skilled contractors.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> getPlaceholderProject() {
    return {
      'title': 'N/A',
      'description': 'You have no active projects at the moment.',
      'type': 'N/A',
      'contractee_name': 'No Contractee',
      'contractee_photo': null,
      'status': 'inactive',
      'isPlaceholder': true,
      'min_budget': 0,
      'max_budget': 0,
      'location': null,
      'start_date': null,
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
          SizedBox(height: isMobile ? 12 : 16),
          ...projectsToShow.map((project) => _buildProjectCard(context, project, supabase)),
        ],
      ),
    );
  }

  static Widget _buildProjectCard(BuildContext context, Map<String, dynamic> project, SupabaseClient supabase) {
    bool isPlaceholder = project['isPlaceholder'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: InkWell(
        onTap: isPlaceholder ? null : () {
          final projectStatus = project['status']?.toString().toLowerCase();
          if (projectStatus != 'active') {
            ConTrustSnackBar.warning(context, 'Project is not active yet. Current status: ${projectStatus ?? 'Unknown'}');
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
                      isPlaceholder ? '' : 'Active',
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
    child: Text(
      "No contractors yet",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade700,
      ),
    ),
  );
}

  static Widget buildBidsContainer({
    required BuildContext context,
    required String projectId,
    required Future<void> Function(String projectId, String bidId) acceptBidding,
    required Future<void> Function(String projectId, String bidId, {String? reason}) rejectBidding,
    String? projectStatus,
    Set<String>? bidsLoading, 
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
            future: BiddingService().getBidsForProject(projectId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading bids'));
              }

              final bids = List<Map<String, dynamic>>.from(snapshot.data ?? []);
              bids.sort((a, b) {
                String sa = (a['status'] ?? 'pending').toString().toLowerCase();
                String sb = (b['status'] ?? 'pending').toString().toLowerCase();
                int rank(String s) {
                  switch (s) {
                    case 'accepted':
                      return 0;
                    case 'pending':
                      return 1;
                    case 'rejected':
                      return 2;
                    default:
                      return 3;
                  }
                }
                final r = rank(sa).compareTo(rank(sb));
                if (r != 0) return r;
                final na = (a['bid_amount'] is num) ? (a['bid_amount'] as num).toDouble() : 0.0;
                final nb = (b['bid_amount'] is num) ? (b['bid_amount'] as num).toDouble() : 0.0;
                return nb.compareTo(na);
              });

              if (bids.isEmpty) {
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
                        'No bids received yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bids from contractors will appear here',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final screenWidth = MediaQuery.of(context).size.width;
              final isMobile = screenWidth < 600;
              return SizedBox(
                height: isMobile ? 150 : 200,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    final bidKey = '$projectId-${bid['bid_id']}';
                    final isLoading = bidsLoading?.contains(bidKey) ?? false;
                    return _buildCompactBidCard(
                      context: context,
                      bid: bid,
                      onAccept: () => acceptBidding(projectId, bid['bid_id']),
                      onReject: (String? reason) => rejectBidding(projectId, bid['bid_id'], reason: reason),
                      projectStatus: projectStatus,
                      isLoading: isLoading,
                    );
                  },
                ),
              );
            },
          );
  }

  static Widget _buildCompactBidCard({
    required BuildContext context,
    required Map<String, dynamic> bid,
    required VoidCallback onAccept,
    required void Function(String? reason) onReject,
    String? projectStatus,
    bool isLoading = false,
  }) {
    final contractor = bid['contractor'] as Map<String, dynamic>?;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isAccepted = bid['status'] == 'accepted';
    final isRejected = bid['status'] == 'rejected';
    final canAccept = projectStatus == 'pending' && !isAccepted && !isRejected;
    final canReject = projectStatus == 'pending' && !isAccepted && !isRejected;
    final projectStatusLower = projectStatus?.toLowerCase();
    final showMessageButton =
        projectStatusLower == null || projectStatusLower == 'pending';

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 18 : 20,
                child: ClipOval(
                  child: Image.network(
                    contractor != null &&
                            contractor['profile_photo'] != null &&
                            contractor['profile_photo']
                                .toString()
                                .isNotEmpty
                        ? contractor['profile_photo']
                        : profileUrl,
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
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'by ${contractor?['firm_name'] ?? 'Unknown Contractor'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showMessageButton)
                    IconButton(
                      onPressed: isLoading
                          ? null
                          : () => _handleMessageTap(context, bid),
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        size: isMobile ? 18 : 20,
                      ),
                      tooltip: 'Message Contractor',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: isMobile ? 20 : 22,
                        minHeight: isMobile ? 20 : 22,
                      ),
                    ),
                  if (showMessageButton)
                    SizedBox(width: isMobile ? 1 : 2),
                  IconButton(
                    onPressed: () => _showBidInfoDialog(context, bid),
                    icon: Icon(
                      Icons.info_outline,
                      size: isMobile ? 18 : 20,
                    ),
                    tooltip: 'More Info',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 20 : 22,
                      minHeight: isMobile ? 20 : 22,
                    ),
                  ),
                  if (isAccepted || isRejected) ...[
                    SizedBox(width: isMobile ? 3 : 4),
                    if (isAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACCEPTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'REJECTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ] else if (canAccept || canReject) ...[
                    SizedBox(width: isMobile ? 3 : 4),
                    IconButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              _showRejectBidDialog(
                                  context,
                                  bid,
                                  (String? reason) => onReject(reason));
                            },
                      icon:
                          Icon(Icons.close, size: isMobile ? 16 : 18),
                      tooltip: 'Decline',
                      padding: EdgeInsets.all(isMobile ? 3 : 4),
                      constraints: BoxConstraints(
                        minWidth: isMobile ? 28 : 32,
                        minHeight: isMobile ? 28 : 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(width: isMobile ? 3 : 4),
                    IconButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              _showAcceptBidDialog(context, bid, onAccept);
                            },
                      icon:
                          Icon(Icons.check, size: isMobile ? 16 : 18),
                      tooltip: 'Accept',
                      padding: EdgeInsets.all(isMobile ? 3 : 4),
                      constraints: BoxConstraints(
                        minWidth: isMobile ? 28 : 32,
                        minHeight: isMobile ? 28 : 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static void _showBidInfoDialog(BuildContext context, Map<String, dynamic> bid) {
    final contractor = bid['contractor'] as Map<String, dynamic>?;
    final info = {
      'project_title': bid['project_title'] ?? 'Bid for Project',
      'firm_name': contractor?['firm_name'] ?? 'Unknown Contractor',
      'profile_photo': contractor?['profile_photo'],
      'email': contractor?['email'],
      'bid_amount': bid['bid_amount']?.toString() ?? '0',
      'message': bid['message'] ?? 'No description provided',
      'status': bid['status'] ?? 'pending',
    };
    
    showDialog(
      context: context,
      barrierDismissible: true,
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
                            "Bid Details",
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
                                    info['profile_photo'] != null && info['profile_photo'].toString().isNotEmpty
                                        ? info['profile_photo']
                                        : profileUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image(
                                        image: const AssetImage('assets/defaultpic.png'),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                            Icons.business,
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
                                      info['firm_name'] ?? 'Unknown Contractor',
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
                          _buildDetailField('Bid Amount', '₱${info['bid_amount']}', isDesktop),
                          _buildDetailField('Contractor Message', info['message'] ?? 'No description provided', isDesktop),
                          _buildDetailField('Status', (info['status'] as String).toUpperCase(), isDesktop),
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

  static String _getProjectPhotoUrl(dynamic photoUrl) {
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

  static void _showFullPhotoDialog(BuildContext context, String url) {
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

  static Widget _buildDetailField(String label, String value, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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

  static Widget _buildProjectPhotoButton(BuildContext context, dynamic photoUrl, bool isDesktop) {
    final photoUrlString = _getProjectPhotoUrl(photoUrl);
    if (photoUrlString.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                    onPressed: () => _showFullPhotoDialog(context, photoUrlString),
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
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFullPhotoDialog(context, photoUrlString),
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

  static void _showAcceptBidDialog(
    BuildContext context,
    Map<String, dynamic> bid,
    VoidCallback onAccept,
  ) {
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Accept Bid'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to accept this bid?'),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone. The contractor will be notified and the project will proceed.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAccept();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept Bid'),
            ),
          ],
        );
      },
    );
  }

  static void _showRejectBidDialog(
    BuildContext context,
    Map<String, dynamic> bid,
    void Function(String? reason) onReject,
  ) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade600),
              const SizedBox(width: 12),
              const Text('Reject Bid'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to reject this bid?'),
              const SizedBox(height: 16),
              const Text(
                'Reason for rejection (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'The contractor will be notified about this rejection.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim().isEmpty 
                    ? null 
                    : reasonController.text.trim();
                Navigator.of(dialogContext).pop();
                onReject(reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject Bid'),
            ),
          ],
        );
      },
    );
  }

  static Widget buildHiringBidsEmptyStateContainer({
    required BuildContext context,
    required List<Map<String, dynamic>> projects,
    required Future<void> Function(String projectId, String bidId) acceptBidding,
    required Future<void> Function(String projectId, String bidId, {String? reason}) rejectBidding,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    // Filter out placeholder projects
    final realProjects = projects.where((p) => p['isPlaceholder'] != true).toList();

    // If no projects, show generic empty state
    if (realProjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 16),
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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 32),
          child: Column(
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: isMobile ? 48 : 64,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'No Projects Yet',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Create your first project to get started',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Find active/pending projects to determine hiring type
    Map<String, dynamic>? activeProject;
    try {
      activeProject = realProjects.firstWhere(
        (p) => ['active', 'awaiting_contract', 'awaiting_agreement', 'awaiting_signature', 'pending']
            .contains(p['status']?.toString().toLowerCase()),
      );
    } catch (e) {
      // If no active/pending, use the first project
      if (realProjects.isNotEmpty) {
        activeProject = realProjects.first;
      }
    }

    // Get hiring type from project data
    final projectData = activeProject?['projectdata'] as Map<String, dynamic>?;
    final hiringType = projectData?['hiring_type'] ?? 'bidding';
    final isDirectHire = hiringType == 'direct_hire';
    final projectId = activeProject?['project_id']?.toString() ?? '';

    // Build the appropriate container based on hiring type
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 16),
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
              Icon(
                isDirectHire ? Icons.person_add : Icons.format_list_bulleted,
                color: Colors.amber[700],
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDirectHire 
                      ? "Hiring Request Sent To"
                      : "Bids for Your Projects",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isDirectHire
              ? buildHiringRequestsContainer(
                  context: context,
                  projectId: projectId,
                )
              : buildBidsContainer(
                  context: context,
                  projectId: projectId.isNotEmpty ? projectId : '',
                  acceptBidding: acceptBidding,
                  rejectBidding: rejectBidding,
                  projectStatus: activeProject?['status'],
                ),
        ],
      ),
    );
  }

  static Widget buildHiringRequestsContainer({
    required BuildContext context,
    required String projectId,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FetchService().fetchHiringRequestsForProject(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading hiring requests',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
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
                  'No hiring requests sent yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hiring requests sent to contractors will appear here',
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

        final acceptedRequest = requests.firstWhere(
          (r) {
            final info = r['information'];
            if (info is Map) {
              return info['status'] == 'accepted';
            }
            return false;
          },
          orElse: () => <String, dynamic>{},
        );

        final pendingRequests = requests.where((r) {
          final info = r['information'];
          if (info is Map) {
            return info['status'] == 'pending';
          }
          return false;
        }).toList();

        final rejectedRequests = requests.where((r) {
          final info = r['information'];
          if (info is Map) {
            final s = (info['status'] ?? 'pending').toString().toLowerCase();
            return s == 'rejected' || s == 'declined' || s == 'cancelled';
          }
          return false;
        }).toList();

        final items = <Widget>[];
        if (acceptedRequest.isNotEmpty) {
          items.add(_buildHiringRequestCard(
            context: context,
            request: acceptedRequest,
            isAccepted: true,
            isMobile: isMobile,
          ));
          if (pendingRequests.isNotEmpty || rejectedRequests.isNotEmpty) {
            items.add(const SizedBox(height: 8));
          }
        }
        for (final request in pendingRequests) {
          items.add(_buildHiringRequestCard(
            context: context,
            request: request,
            isAccepted: false,
            isMobile: isMobile,
          ));
        }
        if (rejectedRequests.isNotEmpty && (acceptedRequest.isNotEmpty || pendingRequests.isNotEmpty)) {
          items.add(const SizedBox(height: 8));
        }
        for (final request in rejectedRequests) {
          items.add(_buildHiringRequestCard(
            context: context,
            request: request,
            isAccepted: false,
            isMobile: isMobile,
          ));
        }

        return SizedBox(
          height: isMobile ? 150 : 200,
          child: ListView(
            padding: EdgeInsets.zero,
            children: items,
          ),
        );
      },
    );
  }

  static Widget _buildHiringRequestCard({
    required BuildContext context,
    required Map<String, dynamic> request,
    required bool isAccepted,
    required bool isMobile,
  }) {
    final info = request['information'];
    Map<String, dynamic> infoMap = {};
    
    if (info is Map) {
      infoMap = Map<String, dynamic>.from(info);
    } else if (info is String) {
      try {
        infoMap = Map<String, dynamic>.from(
          Map<String, dynamic>.from({}),
        );
      } catch (_) {}
    }

    final firmName = infoMap['firm_name'] ?? 'Unknown Contractor';
    final status = (infoMap['status'] ?? 'pending').toString().toLowerCase();
    final isRejected = status == 'rejected' || status == 'declined' || status == 'cancelled';
    final projectId = infoMap['project_id']?.toString();
    final contractorId = request['receiver_id']?.toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 18 : 20,
            child: ClipOval(
              child: Image.network(
                infoMap['profile_photo'] != null && infoMap['profile_photo'].toString().isNotEmpty
                    ? infoMap['profile_photo']
                    : profileUrl,
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
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  infoMap['project_title'] ?? 'Hiring Request',
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
                  'to $firmName',
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
              if (contractorId != null && contractorId.isNotEmpty &&
                  projectId != null && projectId.isNotEmpty)
                IconButton(
                  onPressed: () {
                    final pseudoBid = <String, dynamic>{
                      'contractor_id': contractorId,
                      'project_id': projectId,
                      'contractor': {
                        'firm_name': firmName,
                        'profile_photo': infoMap['profile_photo'],
                      },
                    };
                    _handleMessageTap(context, pseudoBid);
                  },
                  icon: Icon(Icons.chat_bubble_outline,
                      size: isMobile ? 18 : 20),
                  tooltip: 'Message Contractor',
                  padding: EdgeInsets.all(isMobile ? 3 : 4),
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 28 : 32,
                    minHeight: isMobile ? 28 : 32,
                  ),
                ),
              if (contractorId != null && contractorId.isNotEmpty &&
                  projectId != null && projectId.isNotEmpty)
                SizedBox(width: isMobile ? 3 : 4),
              IconButton(
                onPressed: () =>
                    _showHiringRequestInfoDialog(context, request),
                icon: Icon(Icons.info_outline, size: isMobile ? 18 : 20),
                tooltip: 'More Info',
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 28 : 32,
                  minHeight: isMobile ? 28 : 32,
                ),
              ),
              if (isAccepted || status == 'accepted') ...[
                SizedBox(width: isMobile ? 3 : 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACCEPTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (isRejected) ...[
                SizedBox(width: isMobile ? 3 : 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'REJECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static void _showHiringRequestInfoDialog(BuildContext context, Map<String, dynamic> request) {
    final info = request['information'];
    Map<String, dynamic> infoMap = {};
    
    if (info is Map) {
      infoMap = Map<String, dynamic>.from(info);
    }
    
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
                                    infoMap['profile_photo'] != null && infoMap['profile_photo'].toString().isNotEmpty
                                        ? infoMap['profile_photo']
                                        : profileUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image(
                                        image: const AssetImage('assets/defaultpic.png'),
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
                                      infoMap['firm_name'] ?? 'Unknown Contractor',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      infoMap['email'] ?? 'No email provided',
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
                          if (infoMap['photo_url'] != null && infoMap['photo_url'].toString().isNotEmpty) ...[
                            _buildProjectPhotoButton(context, infoMap['photo_url'], isDesktop),
                            const SizedBox(height: 16),
                          ],
                          _buildDetailField('Project Title', infoMap['project_title'] ?? 'Untitled Project', isDesktop),
                          _buildDetailField('Project Type', infoMap['project_type'] ?? 'Not specified', isDesktop),
                          _buildDetailField('Location', infoMap['project_location'] ?? 'Not specified', isDesktop),
                          _buildDetailField('Description', infoMap['project_description'] ?? 'No description provided', isDesktop),
                          
                          if (infoMap['min_budget'] != null && infoMap['max_budget'] != null)
                            _buildDetailField('Budget Range', '₱${infoMap['min_budget']} - ₱${infoMap['max_budget']}', isDesktop)
                          else if (infoMap['project_budget'] != null)
                            _buildDetailField('Budget', '₱${infoMap['project_budget']}', isDesktop)
                          else
                            _buildDetailField('Budget', 'Not specified', isDesktop),
                          
                          if (infoMap['start_date'] != null)
                            _buildDetailField('Preferred Start Date', infoMap['start_date'].toString().split(' ')[0], isDesktop),
                          
                          if (infoMap['additional_info'] != null && infoMap['additional_info'].isNotEmpty)
                            _buildDetailField('Additional Information', infoMap['additional_info'], isDesktop),
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

  static Widget buildContractorsSection({
    required BuildContext context,
    required bool isLoading,
    required List<Map<String, dynamic>> filteredContractors,
    required TextEditingController searchController,
    required int selectedIndex,
    required Function(int) onSelect,
    required String profileUrl,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
              Icon(Icons.business, color: Colors.amber[700], size: isMobile ? 20 : 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Suggested Contractor Firms",
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: isMobile ? 45 : 54,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search contractors...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
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
          const SizedBox(height: 8),
          Column(
            children: [
              SizedBox(
                height: isMobile ? 210 : 420,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                    : filteredContractors.isEmpty
                        ? buildNoContractorsPlaceholder(searchController)
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredContractors.length > 5 ? 5 : filteredContractors.length,
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
                                  width: isMobile ? 160 : 260,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : 16,
                                  ),
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
                                    rating: (contractor['rating'] ?? 0.0).toDouble(),
                                    isMobile: isMobile,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (filteredContractors.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: TextButton(
                      onPressed: () => _showAllContractorsDialog(
                        context: context,
                        contractors: filteredContractors,
                        selectedIndex: selectedIndex,
                        onSelect: onSelect,
                        profileUrl: profileUrl,
                      ),
                      child: Text(
                        'See More',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  static Widget buildActiveProjectsContainer({
    required BuildContext context,
    required Widget projectContent,
    required VoidCallback onPostProject,
    bool isPostingProject = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 600;

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
                Expanded(
                  child: Text(
                    'Active Projects',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                isMobile
                    ? IconButton(
                        onPressed: isPostingProject ? null : onPostProject,
                        icon: isPostingProject 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: isPostingProject ? Colors.grey[400] : Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: isPostingProject ? 'Posting...' : 'Post Project',
                      )
                    : ElevatedButton.icon(
                        onPressed: isPostingProject ? null : onPostProject,
                        icon: isPostingProject 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add, size: 18),
                        label: Text(isPostingProject ? 'Posting...' : 'Post Project'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPostingProject ? Colors.grey[400] : Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            projectContent,
          ],
        ),
      ),
    );
  }

  static Widget buildCurrentContractorContainer({
    required BuildContext context,
    required String projectId,
  }) {
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
                Expanded(
                  child: Text(
                    'Current Contractor',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchCurrentContractor(projectId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading contractor',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  );
                }

                final contractor = snapshot.data;
                
                if (contractor == null) {
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
                          'No contractor assigned',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A contractor will appear here.',
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

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: contractor['profile_photo'] != null && contractor['profile_photo'].toString().isNotEmpty
                            ? NetworkImage(contractor['profile_photo'])
                            : null,
                        child: contractor['profile_photo'] == null || contractor['profile_photo'].toString().isEmpty
                            ? Icon(
                                Icons.person,
                                color: Colors.grey.shade600,
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
                              contractor['firm_name']?.toString() ?? "Contractor Name",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (contractor['email'] != null && (contractor['email'] as String).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                contractor['email'],
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
                        onPressed: () async {
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
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showAllContractorsDialog({
    required BuildContext context,
    required List<Map<String, dynamic>> contractors,
    required int selectedIndex,
    required Function(int) onSelect,
    required String profileUrl,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final router = GoRouter.of(context);
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.all(isMobile ? 16 : 100),
        child: Container(
          width: isMobile ? double.infinity : (screenWidth * 0.55),
          height: isMobile
              ? MediaQuery.of(dialogContext).size.height * 0.8
              : MediaQuery.of(dialogContext).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, color: Colors.white, size: isMobile ? 24 : 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All Contractor Firms',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: contractors.length,
                    itemBuilder: (gridContext, index) {
                      final contractor = contractors[index];
                      final profilePhoto = contractor['profile_photo'];
                      final profileImage =
                          (profilePhoto == null || profilePhoto.isEmpty)
                              ? profileUrl
                              : profilePhoto;
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          onSelect(index);
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
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
                            rating: (contractor['rating'] ?? 0.0).toDouble(),
                            isMobile: true,
                            onViewPressed: () {
                              final contractorName =
                                  contractor['firm_name'] ?? 'Unknown';
                              final encodedName =
                                  Uri.encodeComponent(contractorName);

                              Navigator.of(dialogContext).pop();
                              router.go('/contractor/$encodedName');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>?> _fetchCurrentContractor(String projectId) async {
    try {
      if (projectId.isEmpty) return null;
      
      final supabase = Supabase.instance.client;
      
      final projectResponse = await supabase
          .from('Projects')
          .select('contractor_id')
          .eq('project_id', projectId)
          .maybeSingle();
      
      if (projectResponse == null) return null;
      
      final contractorId = projectResponse['contractor_id'] as String?;
      if (contractorId == null || contractorId.isEmpty) return null;
      
      final contractorResponse = await supabase
          .from('Contractor')
          .select('contractor_id, firm_name, specialization, bio, profile_photo, verified, rating')
          .eq('contractor_id', contractorId)
          .maybeSingle();
      
      if (contractorResponse == null) return null;
      
      String email = '';
      try {
        final userData = await supabase
            .from('Users')
            .select('email')
            .eq('users_id', contractorId)
            .maybeSingle();
        if (userData != null) {
          email = userData['email'] ?? '';
        }
      } catch (e) {
        //
      }
      
      final contractorData = Map<String, dynamic>.from(contractorResponse);
      contractorData['email'] = email;
      
      return contractorData;
    } catch (e) {
      return null;
    }
  }
}

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_UIapp.dart';
import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
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
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
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
            : Column(
                children: [
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Completed",
                          "${projects.where((p) => p['status'] == 'ended').length}",
                          Icons.check_circle,
                          Colors.black,
                          isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox.shrink(),
                      ),
                    ],
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
      'title': 'No Active Projects',
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
                    contractor != null && contractor['profile_photo'] != null && contractor['profile_photo'].toString().isNotEmpty
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
              IconButton(
                onPressed: () => _showBidInfoDialog(context, bid),
                icon: Icon(Icons.info_outline, size: isMobile ? 18 : 20),
                tooltip: 'More Info',
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 28 : 32, 
                  minHeight: isMobile ? 28 : 32
                ),
              ),
                  if (isAccepted || isRejected) ...[
                    SizedBox(width: isMobile ? 3 : 4),
                    if (isAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  ]
                  else if (canAccept || canReject) ...[
                    SizedBox(width: isMobile ? 3 : 4),
                    IconButton(
                      onPressed: isLoading ? null : () {
                        _showRejectBidDialog(context, bid, (String? reason) => onReject(reason));
                      },
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
                      onPressed: isLoading ? null : () {
                        _showAcceptBidDialog(context, bid, onAccept);
                      },
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
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
                                      return Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.grey.shade400,
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
                          
                          _buildDetailField('Bid Amount', '₱${info['bid_amount']}'),
                          _buildDetailField('Contractor Message', info['message'] ?? 'No description provided'),
                          _buildDetailField('Status', (info['status'] as String).toUpperCase()),
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

  static Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
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
              IconButton(
                onPressed: () => _showHiringRequestInfoDialog(context, request),
                icon: Icon(Icons.info_outline, size: isMobile ? 18 : 20),
                tooltip: 'More Info',
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 28 : 32, 
                  minHeight: isMobile ? 28 : 32
                ),
              ),
              if (isAccepted || status == 'accepted') ...[
                SizedBox(width: isMobile ? 3 : 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              ]
              else if (isRejected) ...[
                SizedBox(width: isMobile ? 3 : 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        return Center(
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
                                      return Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.grey.shade400,
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
                                      infoMap['full_name'] ?? 'Unknown Client',
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
                          
                          _buildDetailField('Project Title', infoMap['project_title'] ?? 'Untitled Project'),
                          _buildDetailField('Project Type', infoMap['project_type'] ?? 'Not specified'),
                          _buildDetailField('Location', infoMap['project_location'] ?? 'Not specified'),
                          _buildDetailField('Description', infoMap['project_description'] ?? 'No description provided'),
                          
                          if (infoMap['min_budget'] != null && infoMap['max_budget'] != null)
                            _buildDetailField('Budget Range', '₱${infoMap['min_budget']} - ₱${infoMap['max_budget']}')
                          else if (infoMap['project_budget'] != null)
                            _buildDetailField('Budget', '₱${infoMap['project_budget']}')
                          else
                            _buildDetailField('Budget', 'Not specified'),
                          
                          if (infoMap['start_date'] != null)
                            _buildDetailField('Preferred Start Date', infoMap['start_date'].toString().split(' ')[0]),
                          
                          if (infoMap['additional_info'] != null && infoMap['additional_info'].isNotEmpty)
                            _buildDetailField('Additional Information', infoMap['additional_info']),
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
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                    fontSize: isMobile ? 18 : 20,
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
            height: 45,
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
                height: isMobile ? 200 : 260,
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
                                  width: isMobile ? 160 : 200,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : 10,
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
                ElevatedButton.icon(
                  onPressed: onPostProject,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
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
                Text(
                  'Current Contractor',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
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
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
        child: Container(
          width: isMobile ? double.infinity : screenWidth * 0.8,
          height: isMobile ? MediaQuery.of(context).size.height * 0.8 : MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
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
                          fontSize: isMobile ? 20 : 24,
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
              // Scrollable content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contractors.length,
                    itemBuilder: (context, index) {
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
                          width: isMobile ? 160 : 220,
                          margin: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
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

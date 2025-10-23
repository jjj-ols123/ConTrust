// ignore_for_file: deprecated_member_use, use_super_parameters, file_names
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/contractor services/cor_biddingservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:contractee/build/builddrawer.dart';
import 'package:contractee/pages/cee_torprofile.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';

class ContractorsView extends StatelessWidget {
  final String id;
  final String name;
  final String profileImage;

  static const String profileUrl =
      'https://bgihfdqruamnjionhkeq.supabase.co/storage/v1/object/public/profilephotos/defaultpic.png';

  const ContractorsView({
    Key? key,
    required this.id,
    required this.name,
    required this.profileImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 180,
      height: 220,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.amber.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                (profileImage.isNotEmpty) ? profileImage : profileUrl,
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    profileUrl,
                    height: 160,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                 ElevatedButton(
                    onPressed: () {
                      CheckUserLogin.isLoggedIn(
                        context: context,
                        onAuthenticated: () async {
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContracteeShell(
                                currentPage: ContracteePage.home, 
                                child: ContractorProfileScreen(
                                  contractorId: id,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text("View"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectView extends StatelessWidget {
  final Map<String, dynamic> project;
  final String projectId;
  final double highestBid;
  final int duration;
  final DateTime createdAt;
  final Function() onTap;
  final Function(String) handleFinalizeBidding;
  final Function(String)? onDeleteProject;

  const ProjectView({
    Key? key,
    required this.project,
    required this.projectId,
    required this.highestBid,
    required this.duration,
    required this.createdAt,
    required this.onTap,
    required this.handleFinalizeBidding,
    this.onDeleteProject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHiringRequest =
        project['min_budget'] == null && project['max_budget'] == null;
    final ProjectStatus status = ProjectStatus();

    return InkWell(
      onTap: isHiringRequest ? null : onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.amber.withOpacity(0.5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
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
                        fontSize: 25,
                      ),
                    ),
                  ),
                  if (!isHiringRequest) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border:
                            Border.all(color: Colors.amber.shade200, width: 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "₱${project['min_budget']?.toString() ?? '0'} - ₱${project['max_budget']?.toString() ?? '0'}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                  if (onDeleteProject != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final bool? shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  'Delete Project',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Are you sure you want to delete this project? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldDelete == true) {
                            onDeleteProject!(projectId);
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete Project',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (project['type'] != null)
                Row(
                  children: [
                    const Icon(Icons.category_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Type: ${project['type']}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                project['description'] ?? 'No description',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status
                          .getStatusColor(project['status'])
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "Status: ${status.getStatusLabel(project['status'])}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: status.getStatusColor(project['status']),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isHiringRequest) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    StreamBuilder<Duration>(
                      stream: CorBiddingService()
                          .getBiddingCountdownStream(createdAt, duration),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text(
                            "Loading...",
                            style: TextStyle(fontSize: 14),
                          );
                        }
                        final remaining = snapshot.data!;
                        if (remaining.isNegative) {
                          handleFinalizeBidding(projectId);
                        }
                        if (remaining.isNegative) {
                          return Text(
                            "Closed",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        final days = remaining.inDays;
                        final hours = remaining.inHours
                            .remainder(24)
                            .toString()
                            .padLeft(2, '0');
                        final minutes = remaining.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        final seconds = remaining.inSeconds
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        return Text(
                          '$days d $hours:$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.money,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "₱${highestBid.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (isHiringRequest) ...[
                const SizedBox(height: 18),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      FetchService().fetchHiringRequestsForProject(projectId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final requests = snapshot.data!;
                    final accepted = requests.firstWhere(
                      (r) => r['information']?['status'] == 'accepted',
                      orElse: () => {},
                    );
                    
                    if (accepted.isNotEmpty) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.verified, color: Colors.green),
                        title: Text('Accepted Contractor: '
                            '${accepted['information']?['firm_name'] ?? 'Unknown'}'),
                      );
                    }
                    
                    final pendingRequests = requests.where(
                      (r) => r['information']?['status'] == 'pending'
                    ).toList();
                    
                    if (pendingRequests.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hiring Request Sent To:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...pendingRequests.map((r) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.business),
                                title: Text(r['information']?['firm_name'] ??
                                    'Unknown'),
                                subtitle: const Text('Status: Pending'),
                              )),
                        ],
                      );
                    } else {
                      return const Text('No hiring requests sent.');
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

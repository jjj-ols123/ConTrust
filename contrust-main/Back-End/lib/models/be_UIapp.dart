// ignore_for_file: deprecated_member_use
import 'package:backend/services/be_bidding_service.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:contractee/models/cee_expandable.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:contractee/pages/cee_chathistory.dart';
import 'package:contractee/pages/cee_torprofile.dart';
import 'package:flutter/material.dart';
import 'package:contractee/services/cee_checkuser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                              builder: (context) => ContractorProfileScreen(
                                contractorId: id,
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

    return InkWell(
      onTap: isHiringRequest ? null : onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 18),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                  if (!isHiringRequest) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "₱${project['min_budget']?.toString() ?? '0'} - ₱${project['max_budget']?.toString() ?? '0'}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  if (onDeleteProject != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final bool? shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Project'),
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
                    Text(
                      'Type: ${project['type']}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Description: ${project['description'] ?? 'No description'}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          getStatusColor(project['status']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Status: ${getStatusLabel(project['status'])}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(project['status']),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isHiringRequest) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    StreamBuilder<Duration>(
                      stream: BiddingService()
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
                            style: TextStyle(
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
                    const Icon(Icons.attach_money_outlined,
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
                  future: FetchService().fetchHiringRequestsForProject(projectId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final requests = snapshot.data!;
                    final accepted = requests.firstWhere(
                      (r) => r['information']?['status'] == 'accepted',
                      orElse: () => {},
                    );
                    if (accepted.isNotEmpty) {
                      return ListTile(
                        leading: const Icon(Icons.verified, color: Colors.green),
                        title: Text('Accepted Contractor: '
                          '${accepted['information']?['firm_name'] ?? 'Unknown'}'),
                      );
                    } else if (requests.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hiring Request Sent To:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...requests.map((r) => ListTile(
                            leading: const Icon(Icons.business),
                            title: Text(r['information']?['firm_name'] ?? 'Unknown'),
                            subtitle: Text('Status: '
                              '${(r['information']?['status'] ?? 'pending').toString().capitalize()}'),
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

  String getStatusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'awaiting_contract':
        return 'Awaiting for Contract';
      case 'awaiting_agreement':
        return 'Awaiting Agreement';
      case 'closed':
        return 'Closed';
      case 'ended':
        return 'Ended';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'awaiting_contract':
        return Colors.blue;
      case 'awaiting_agreement':
        return Colors.purple;
      case 'closed':
        return Colors.redAccent;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class ExpandableFloatingButton extends StatelessWidget {
  final VoidCallback clearControllers;
  final VoidCallback? onRefresh;
  final TextEditingController title;
  final TextEditingController typeConstruction;
  final TextEditingController minBudget;
  final TextEditingController maxBudget;
  final TextEditingController location;
  final TextEditingController description;
  final TextEditingController bidTime;

  const ExpandableFloatingButton({
    Key? key,
    required this.clearControllers,
    this.onRefresh,
    required this.title,
    required this.typeConstruction,
    required this.minBudget,
    required this.maxBudget,
    required this.location,
    required this.description,
    required this.bidTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableFloating(
      distance: 120,
      children: [
        FloatingActionButton(
          heroTag: 'projectButton',
          onPressed: () async {
            try {
              CheckUserLogin.isLoggedIn(
                context: context,
                onAuthenticated: () async {
                  if (!context.mounted) return;

                  final user = Supabase.instance.client.auth.currentUser?.id;
                  if (user == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not authenticated')),
                    );
                    return;
                  }

                  if (!context.mounted) return;

                  clearControllers();

                  await ProjectModal.show(
                    context: context,
                    contracteeId: user,
                    titleController: title,
                    constructionTypeController: typeConstruction,
                    minBudgetController: minBudget,
                    maxBudgetController: maxBudget,
                    locationController: location,
                    descriptionController: description,
                    bidTimeController: bidTime,
                  );
                  onRefresh?.call();
                },
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error showing modal')),
              );
            }
          },
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.black,
          hoverColor: Colors.amber[800],
          child: const Icon(Icons.construction, color: Colors.black),
        ),
        FloatingActionButton(
          heroTag: 'cameraButton',
          onPressed: () {
            CheckUserLogin.isLoggedIn(
              context: context,
              onAuthenticated: () async {},
            );
          },
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.black,
          hoverColor: Colors.amber[800],
          child: const Icon(Icons.camera_alt, color: Colors.black),
        ),
        FloatingActionButton(
          heroTag: 'messageButton',
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.black,
          hoverColor: Colors.amber[800],
          child: const Icon(Icons.message),
          onPressed: () {
            CheckUserLogin.isLoggedIn(
              context: context,
              onAuthenticated: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContracteeChatHistoryPage(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:backend/services/getuserdata.dart';
import 'package:backend/services/projectbidding.dart';
import 'package:contractee/models/cee_expandable.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:contractee/pages/cee_chathistory.dart';
import 'package:contractee/pages/cee_torprofile.dart';
import 'package:contractor/Screen/cor_contracttype.dart';
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

  const ProjectView({
    Key? key,
    required this.project,
    required this.projectId,
    required this.highestBid,
    required this.duration,
    required this.createdAt,
    required this.onTap,
    required this.handleFinalizeBidding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                  Text(
                    project['type'] ?? 'No type specified',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "₱${project['min_budget']} - ₱${project['max_budget']}",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project['description'] ?? 'No description',
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  StreamBuilder<Duration>(
                    stream:
                        ProjectBidding().countdownStream(createdAt, duration),
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
  final TextEditingController typeConstruction;
  final TextEditingController minBudget;
  final TextEditingController maxBudget;
  final TextEditingController location;
  final TextEditingController description;
  final TextEditingController bidTime;

  const ExpandableFloatingButton({
    Key? key,
    required this.clearControllers,
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
                    constructionTypeController: typeConstruction,
                    minBudgetController: minBudget,
                    maxBudgetController: maxBudget,
                    locationController: location,
                    descriptionController: description,
                    bidTimeController: bidTime,
                  );
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

class ContractAgreementBanner extends StatefulWidget {
  final String chatRoomId;
  final String userRole;

  const ContractAgreementBanner({
    super.key,
    required this.chatRoomId,
    required this.userRole,
  });

  @override
  State<ContractAgreementBanner> createState() =>
      _ContractAgreementBannerState();
}

class _ContractAgreementBannerState extends State<ContractAgreementBanner> {
  final supabase = Supabase.instance.client;
  GetUserData _getUserData = GetUserData();
  bool _dialogShown = false;

  late final StreamSubscription _projectSubscription;

  @override
  void initState() {
    super.initState();
    _checkProject();
  }

  void _checkProject() async {
    final projectId = await _getUserData.getProjectId(widget.chatRoomId);
    if (projectId == null) return;

    _projectSubscription = supabase
        .from('Projects')
        .stream(primaryKey: ['project_id'])
        .eq('project_id', projectId)
        .listen((event) {
          if (event.isNotEmpty) {
            final project = event.first;
            final initiated = project['contract_started'] == true;
            final contractorAgreed = project['contractor_agree'] == true;
            final contracteeAgreed = project['contractee_agree'] == true;

            if (initiated &&
                contractorAgreed &&
                contracteeAgreed &&
                widget.userRole == 'contractor') {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ContractType(
                      contractorId: project['contractor_id'] ?? '',
                    ),
                  ),
                );
              }
              return;
            }

            final isContractor = widget.userRole == 'contractor';
            final hasAgreed = isContractor ? contractorAgreed : contracteeAgreed;

            if (initiated && !hasAgreed && !_dialogShown) {
              _dialogShown = true;
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Contract Agreement'),
                      content: const Text('Do you agree to proceed with the contract?'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await _handleAgree(projectId);
                          },
                          child: const Text('Agree'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Not now'),
                        ),
                      ],
                    ),
                  );
                });
              }
            }
          }
        });
  }

  Future<void> _handleProceed() async {
    final projectId = await _getUserData.getProjectId(widget.chatRoomId);
    if (projectId == null) return;

    await supabase
        .from('Projects')
        .update({'contract_started': true})
        .eq('project_id', projectId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Waiting for the other party to agree...')),
    );

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) setState(() {});
  }

  Future<void> _handleAgree(String projectId) async {
    final column = widget.userRole == 'contractor'
        ? 'contractor_agree'
        : 'contractee_agree';

    await supabase
        .from('Projects')
        .update({column: true})
        .eq('project_id', projectId);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _projectSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "This project is awaiting contract agreement.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Proceed with Contract"),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

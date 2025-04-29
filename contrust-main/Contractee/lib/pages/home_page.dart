// ignore_for_file: deprecated_member_use

import 'package:backend/models/appbar.dart';
import 'package:contractee/services/checkuseracc.dart';
import 'package:contractee/models/modalsheet.dart';
import 'package:contractee/pages/contractor_profile.dart';
import 'package:backend/services/projectbidding.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final modalSheet = ModalClass();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> contractors = [];
  List<Map<String, dynamic>> projects = [];
  Map<String, double> highestBids = {};
  bool isLoading = true;
  final Set<String> _finalizedProjects = {};

  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeConstructionController =
      TextEditingController();
  final TextEditingController _bidTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchContractors();
    fetchProjects();
    fetchHighestBids();
  }

  Future<void> fetchContractors() async {
    try {
      final response = await supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo');
      if (response.isNotEmpty) {
        setState(() {
          contractors = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchProjects() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await supabase
          .from('Projects')
          .select(
            'project_id, type, description, duration, min_budget, max_budget, created_at, status',
          )
          .eq('contractee_id', userId);

      if (response.isNotEmpty) {
        setState(() {
          projects = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchHighestBids() async {
    final highestBidsData = await highestBid();
    setState(() {
      highestBids = highestBidsData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Home"),
      drawer: const MenuDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Suggested Contractor Firms",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 280,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : contractors.isEmpty
                        ? const Center(child: Text("No contractors found"))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: contractors.length,
                            itemBuilder: (context, index) {
                              final contractor = contractors[index];
                              return _buildContractorCard(
                                context,
                                contractor['contractor_id'] ?? '',
                                contractor['firm_name'] ?? 'Unknown',
                                contractor['profile_photo'] ?? '',
                              );
                            },
                          ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Posted Projects",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: fetchProjects,
                    child: Text(
                      "Refresh",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : projects.isEmpty
                      ? const Center(
                          child: Text("You haven't posted any projects yet"),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            final projectId = project['project_id'].toString();
                            final highestBid = highestBids[projectId] ?? 0.0;

                            return _buildProjectCard(
                              context: context,
                              project: project,
                              projectId: projectId,
                              highestBid: highestBid,
                              duration: project['duration'] ?? 0,
                              createdAt: DateTime.parse(
                                  project['created_at'].toString()),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
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

                _clearControllers();

                await ModalClass.show(
                  context: context,
                  contracteeId: user,
                  constructionTypeController: _typeConstructionController,
                  minBudgetController: _minBudgetController,
                  maxBudgetController: _maxBudgetController,
                  locationController: _locationController,
                  descriptionController: _descriptionController,
                  bidTimeController: _bidTimeController,
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
    );
  }

  Widget _buildContractorCard(
      BuildContext context, String id, String name, String profileImage) {
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
                profileImage.isNotEmpty
                    ? profileImage
                    : 'assets/defaultpic.png',
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/defaultpic.png',
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

  void _clearControllers() {
    _typeConstructionController.clear();
    _minBudgetController.clear();
    _maxBudgetController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _bidTimeController.clear();
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required Map<String, dynamic> project,
    required String projectId,
    required double highestBid,
    required int duration,
    required DateTime createdAt,
  }) {
    Color statusColor;
    switch ((project['status'] ?? '').toString().toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'closed':
      case 'ended':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.grey;
    }
    return Card(
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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Status: ${project['status'] ?? 'Unknown'}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  "Duration: ",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                StreamBuilder<Duration>(
                  stream: countdownStream(createdAt, duration),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text(
                        "Loading...",
                        style: TextStyle(fontSize: 14),
                      );
                    }

                    final remaining = snapshot.data!;

                    if (remaining.isNegative &&
                        !_finalizedProjects.contains(projectId)) {
                      _finalizedProjects.add(projectId);
                      finalizeBidding(projectId);
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
                      "$days day/s $hours:$minutes:$seconds",
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
                const Icon(Icons.money, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  "Highest Bid: ",
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "₱${highestBid.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

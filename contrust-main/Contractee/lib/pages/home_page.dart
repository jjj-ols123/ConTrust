// ignore_for_file: deprecated_member_use

import 'package:backend/models/appbar.dart';
import 'package:contractee/models/modalsheet.dart';
import 'package:backend/services/projectbidding.dart';
import 'package:backend/services/fetchmethods.dart';
import 'package:backend/models/buildmethods.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final modalSheet = ProjectModal();
  final projectbidding = ProjectBidding();
  final fetchClass = FetchClass();
  Map<String, double> highestBids = {};


  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> contractors = [];
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedContractors = await fetchClass.fetchContractors();
      final fetchedProjects = await fetchClass.fetchProjects();
      final fetchedHighestBids = await fetchClass.fetchHighestBids();

      setState(() {
        contractors = fetchedContractors;
        projects = fetchedProjects;
        highestBids = fetchedHighestBids;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _loadFinalizeBidding(String projectId) async {
    try {
      await projectbidding.finalizeBidding(projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid has been accepted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error in bidding: $e')),
        );
      }
    }
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
                              return ContractorsView(
                                id: contractor['contractor_id'] ?? '',
                                name: contractor['firm_name'] ?? 'Unknown',
                                profileImage: contractor['profile_photo'] ?? '',
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
                    onPressed: _loadData,
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

                            return ProjectView(
                              project: project,
                              projectId: projectId,
                              highestBid: highestBid,
                              duration: project['duration'] ?? 0,
                              createdAt:
                                  DateTime.parse(project['created_at'].toString()),
                              onTap: () {
                                BidsModal.show(
                                  context: context,
                                  projectId: projectId,
                                  finalizeBidding: projectbidding.finalizeBidding,
                                );
                              },
                              handleFinalizeBidding: _loadFinalizeBidding
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    floatingActionButton: ExpandableFloatingButton(
      clearControllers: _clearControllers,
      typeConstruction: _typeConstructionController,
      minBudget: _minBudgetController,
      maxBudget: _maxBudgetController,
      location: _locationController,
      description: _descriptionController,
      bidTime: _bidTimeController,
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
}


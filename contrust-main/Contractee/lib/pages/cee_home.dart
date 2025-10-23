// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_UIapp.dart';
import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:contractee/build/builddrawer.dart';
import 'package:contractee/build/buildhome.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
  
class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final modalSheet = ProjectModal();
  int selectedIndex = -1;

  Map<String, double> highestBids = {};
  Map<String, String?> acceptedBidIds = {};

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> contractors = [];
  List<Map<String, dynamic>> filteredContractors = [];
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterContractors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContractors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredContractors = contractors;
      } else {
        filteredContractors = contractors.where((contractor) {
          final firmName = contractor['firm_name']?.toString().toLowerCase() ?? '';
          return firmName.contains(query);
        }).toList();
      }
    });
  }
  
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedContractors = await FetchService().fetchContractors();
      List<Map<String, dynamic>> fetchedProjects = [];
      Map<String, double> fetchedHighestBids = {};
      if (supabase.auth.currentUser != null) {
        fetchedProjects = await FetchService().fetchUserProjects();
        fetchedHighestBids = await BiddingService().getProjectHighestBids();
      }

      setState(() {
        contractors = fetchedContractors;
        filteredContractors = fetchedContractors;
        projects = fetchedProjects;
        highestBids = fetchedHighestBids;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ConTrustSnackBar.error(context, 'Unable to load data. Please check your connection.');
    }
  }

  void _loadAcceptBidding(String projectId, String bidId) async {
    try {
      await BiddingService().acceptProjectBid(projectId, bidId);
      if (mounted) {
        ConTrustSnackBar.success(context, 'The bid has been accepted successfully!');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Something went wrong while accepting the bid.');
      }
    }
  }

  void _postProject() {
    CheckUserLogin.isLoggedIn(
      context: context,
      onAuthenticated: () async {
        final contracteeId = supabase.auth.currentUser?.id;
        if (contracteeId != null) {
          final titleController = TextEditingController();
          final typeController = TextEditingController();
          final minBudgetController = TextEditingController();
          final maxBudgetController = TextEditingController();
          final locationController = TextEditingController();
          final descriptionController = TextEditingController();
          final bidTimeController = TextEditingController();

          bidTimeController.text = '7';

          await ProjectModal.show(
            context: context,
            contracteeId: contracteeId,
            titleController: titleController,
            constructionTypeController: typeController,
            minBudgetController: minBudgetController,
            maxBudgetController: maxBudgetController,
            locationController: locationController,
            descriptionController: descriptionController,
            bidTimeController: bidTimeController,
          );

          _loadData();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contracteeId = supabase.auth.currentUser?.id;
    final projectsToShow = projects.isEmpty ? [HomePageBuilder.getPlaceholderProject()] : projects;

    return ContracteeShell(
      currentPage: ContracteePage.home,
      contracteeId: contracteeId,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              HomePageBuilder.buildContractorsSection(
                context: context,
                isLoading: isLoading,
                filteredContractors: filteredContractors,
                searchController: _searchController,
                selectedIndex: selectedIndex,
                onSelect: (index) {
                  CheckUserLogin.isLoggedIn(
                    context: context,
                    onAuthenticated: () {
                      setState(() {
                        selectedIndex = (selectedIndex == index) ? -1 : index;
                      });
                    },
                  );
                },
                profileUrl: HomePageBuilder.profileUrl,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _loadData,
                    child: Text(
                      "Refresh",
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: projectsToShow.length,
                      itemBuilder: (context, index) {
                        final project = projectsToShow[index];
                        final isPlaceholder = project['isPlaceholder'] == true;

                        if (isPlaceholder) {
                          return HomePageBuilder.buildProjectsSection(
                            context: context,
                            projects: [project],
                            supabase: supabase,
                            onPostProject: _postProject,
                          );
                        }

                        final projectId = project['project_id'].toString();
                        final highestBid = highestBids[projectId] ?? 0.0;

                        return FutureBuilder<Map<String, dynamic>>(
                          future: supabase
                              .from('Projects')
                              .select('bid_id')
                              .eq('project_id', projectId)
                              .single(),
                          builder: (context, snapshot) {
                            String? acceptedBidId;
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              acceptedBidId = snapshot.data?['bid_id'];
                            }
                            return ProjectView(
                              project: project,
                              projectId: projectId,
                              highestBid: highestBid,
                              duration: project['duration'] ?? 0,
                              createdAt: DateTime.parse(project['created_at'].toString()),
                              onTap: () {
                                CheckUserLogin.isLoggedIn(
                                  context: context,
                                  onAuthenticated: () async {
                                    await BidsModal.show(
                                      context: context,
                                      projectId: projectId,
                                      acceptBidding: (projectId, bidId) async {
                                        _loadAcceptBidding(projectId, bidId);
                                        setState(() {
                                          acceptedBidIds[projectId] = bidId;
                                        });
                                      },
                                      initialAcceptedBidId: acceptedBidId,
                                      onRefresh: _loadData,  
                                    );
                                  },
                                );
                              },
                              handleFinalizeBidding: (bidId) {
                                return BiddingService().acceptProjectBid(projectId, bidId);
                              },
                              onDeleteProject: (projectId) async {
                                try {
                                  await ProjectService().deleteProject(projectId);
                                  ConTrustSnackBar.success(context, 'The project has been deleted successfully.');
                                  _loadData();
                                } catch (e) {
                                  ConTrustSnackBar.error(context, 'Failed to delete project. Please try again.');
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
              const SizedBox(height: 30),
              HomePageBuilder.buildStatsSection(
                context: context,
                projects: projects,
                contractors: contractors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

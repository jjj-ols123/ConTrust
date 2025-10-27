// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_UIapp.dart';
import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_constraint.dart';
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
      final contracteeId = supabase.auth.currentUser?.id;
      if (contracteeId != null) {
        final ongoingProject = await hasOngoingProject(contracteeId);
        if (ongoingProject != null && ongoingProject['project_id'] != projectId) {
          if (mounted) {
            ConTrustSnackBar.error(
              context,
              'You already have an active project. Complete it before accepting another bid.',
            );
          }
          return;
        }
      }

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
          final ongoingProject = await hasOngoingProject(contracteeId);
          if (ongoingProject != null) {
            ConTrustSnackBar.warning(
              context,
              'You already have an active project. Please complete or cancel your current project before posting a new one.',
            );
            return;
          }

          final pendingProject = await hasPendingProject(contracteeId);
          if (pendingProject != null) {
            ConTrustSnackBar.info(
              context,
              'You already have a pending project: "${pendingProject['title'] ?? 'Untitled'}". Use the menu (⋮) on your project card to update or cancel it.',
            );
            return;
          }

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
            onRefresh: _loadData,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contracteeId = supabase.auth.currentUser?.id;
    final projectsToShow = projects.isEmpty ? [HomePageBuilder.getPlaceholderProject()] : projects;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ContracteeShell(
      currentPage: ContracteePage.home,
      contracteeId: contracteeId,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 15, 
            vertical: isMobile ? 8 : 5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isMobile ? 20 : 30),
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
              SizedBox(height: isMobile ? 12 : 16),
              isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work_outline, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),

                          TextButton(
                            onPressed: _loadData,
                            child: Text(
                              "Refresh",
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _postProject,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Post Your Project', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _postProject,
                            icon: const Icon(Icons.add),
                            label: const Text('Post Your Project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              SizedBox(height: isMobile ? 12 : 15),
              isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
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
                              createdAt: DateTime.parse(project['created_at'].toString()).toLocal(),
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
                                      projectStatus: project['status'],
                                    );
                                  },
                                );
                              },
                              handleFinalizeBidding: (projectId) {
                                return BiddingService().finalizeBidding(projectId);
                              },
                              onUpdateProject: (projectId) async {
                                try {
                                  if (project['status'] != 'pending' && project['status'] != 'stopped') {
                                    if (mounted) {
                                      ConTrustSnackBar.warning(context, 'You cannot update an active project.');
                                    }
                                    return;
                                  }

                                  final projectData = await FetchService().fetchProjectDetails(projectId);
                                  if (projectData == null) {
                                    if (mounted) {
                                      ConTrustSnackBar.error(context, 'Failed to load project details');
                                    }
                                    return;
                                  }

                                  final titleController = TextEditingController(text: projectData['title'] ?? '');
                                  final constructionTypeController = TextEditingController(text: projectData['type'] ?? '');
                                  final minBudgetController = TextEditingController(text: projectData['min_budget'] ?? '');
                                  final maxBudgetController = TextEditingController(text: projectData['max_budget'] ?? '');
                                  final locationController = TextEditingController(text: projectData['location'] ?? '');
                                  final descriptionController = TextEditingController(text: projectData['description'] ?? '');
                                  final bidTimeController = TextEditingController(text: projectData['duration']?.toString() ?? '7');

                                  if (mounted && contracteeId != null) {
                                    await ProjectModal.show(
                                      context: context,
                                      contracteeId: contracteeId,
                                      titleController: titleController,
                                      constructionTypeController: constructionTypeController,
                                      minBudgetController: minBudgetController,
                                      maxBudgetController: maxBudgetController,
                                      locationController: locationController,
                                      descriptionController: descriptionController,
                                      bidTimeController: bidTimeController,
                                      isUpdate: true,
                                      projectId: projectId,
                                      onRefresh: _loadData,
                                    );
                                    
                                    titleController.dispose();
                                    constructionTypeController.dispose();
                                    minBudgetController.dispose();
                                    maxBudgetController.dispose();
                                    locationController.dispose();
                                    descriptionController.dispose();
                                    bidTimeController.dispose();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ConTrustSnackBar.error(context, 'Failed to update project. Please try again.');
                                  }
                                }
                              },
                              onCancelProject: (projectId) async {
                                try {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  await ProjectService().cancelProject(projectId);

                                  await _loadData();

                                  if (mounted) {
                                    final project = projects.firstWhere(
                                      (p) => p['project_id'] == projectId,
                                      orElse: () => {},
                                    );
                                    
                                    if (project.isNotEmpty) {
                                      final status = project['status'] as String?;
                                      if (status == 'cancellation_requested_by_contractee') {
                                        ConTrustSnackBar.info(context, 'Cancellation request sent to contractor. Waiting for approval.');
                                      } else if (status == 'cancelled') {
                                        ConTrustSnackBar.success(context, 'The project has been cancelled successfully.');
                                      }
                                    } else {
                                      ConTrustSnackBar.success(context, 'The project has been cancelled successfully.');
                                    }
                                  }
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  if (mounted) {
                                    ConTrustSnackBar.error(context, 'Failed to cancel project. Please try again.');
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
              SizedBox(height: isMobile ? 20 : 30),
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

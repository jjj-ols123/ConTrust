// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_UIapp.dart';
import 'package:backend/services/both services/be_bidding_service.dart';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_project_service.dart';
import 'package:backend/services/both services/be_realtime_service.dart';
import 'package:backend/services/contractee services/cee_checkuser.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:contractee/models/cee_modal.dart';
import 'package:contractee/build/buildhome.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
  
class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final modalSheet = ProjectModal();
  int selectedIndex = -1;

  Map<String, double> highestBids = {};
  Map<String, String?> acceptedBidIds = {};

  final supabase = Supabase.instance.client;
  final realtimeService = RealtimeSubscriptionService();

  List<Map<String, dynamic>> contractors = [];
  List<Map<String, dynamic>> filteredContractors = [];
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_filterContractors);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
        _setupRealtimeSubscriptions();
      }
    });
  }

  @override
  void dispose() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      realtimeService.unsubscribeFromUserChannels(currentUser.id);
    }
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setupRealtimeSubscriptions() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    // Subscribe to notifications
    realtimeService.subscribeToNotifications(
      userId: currentUser.id,
      onUpdate: () {
        if (mounted) _loadProjectsOnly();
      },
    );

    // Subscribe to contractee projects
    realtimeService.subscribeToContracteeProjects(
      userId: currentUser.id,
      onUpdate: () {
        if (mounted) _loadProjectsOnly();
      },
    );

    // Subscribe to bids for contractee's projects
    realtimeService.subscribeToContracteeBids(
      userId: currentUser.id,
      onUpdate: () {
        if (mounted) _loadProjectsOnly();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && mounted) {
      _loadProjectsOnly();
    }
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
    if (!mounted) return;
    
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

      if (!mounted) return;
      
      setState(() {
        contractors = fetchedContractors;
        filteredContractors = fetchedContractors;
        projects = fetchedProjects;
        highestBids = fetchedHighestBids;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
      ConTrustSnackBar.error(context, 'Unable to load data. Please check your connection.');
    }
  }

  Future<void> _loadProjectsOnly() async {
    if (!mounted) return;
    
    try {
      List<Map<String, dynamic>> fetchedProjects = [];
      Map<String, double> fetchedHighestBids = {};
      if (supabase.auth.currentUser != null) {
        fetchedProjects = await FetchService().fetchUserProjects();
        fetchedHighestBids = await BiddingService().getProjectHighestBids();
      }

      if (!mounted) return;
      
      setState(() {
        projects = fetchedProjects;
        highestBids = fetchedHighestBids;
      });
    } catch (e) {
      if (!mounted) return;
      ConTrustSnackBar.error(context, 'Unable to load projects. Please check your connection.');
    }
  }

  Future<void> _loadAcceptBidding(String projectId, String bidId) async {
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
        _loadProjectsOnly();
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Something went wrong while accepting the bid.');
      }
    }
  }

  Future<void> _handleUpdateProject(String projectId, Map<String, dynamic> project) async {
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

      final contracteeId = supabase.auth.currentUser?.id;
      final titleController = TextEditingController(text: projectData['title'] ?? '');
      final constructionTypeController = TextEditingController(text: projectData['type'] ?? '');
      final minBudgetController = TextEditingController(text: projectData['min_budget'] ?? '');
      final maxBudgetController = TextEditingController(text: projectData['max_budget'] ?? '');
      final locationController = TextEditingController(text: projectData['location'] ?? '');
      final descriptionController = TextEditingController(text: projectData['description'] ?? '');
      final bidTimeController = TextEditingController(text: projectData['duration']?.toString() ?? '7');

      if (mounted && contracteeId != null) {
        final actionTaken = await ProjectModal.show(
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
          onRefresh: _loadProjectsOnly,
          initialStartDate: projectData['start_date'],
        );
        if (actionTaken) {
          ConTrustSnackBar.success(context, 'Project updated successfully!');
          await Future.delayed(const Duration(seconds: 1));
          await _loadProjectsOnly();
        }
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to update project. Please try again.');
      }
    }
  }

  Future<void> _handleCancelProject(String projectId, String reason) async {
    try {
      setState(() {
        isLoading = true;
      });

      await ProjectService().cancelProject(projectId, reason: reason);

      await Future.delayed(const Duration(seconds: 2));
      await _loadProjectsOnly();

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

          final pendingHireRequests = await supabase
              .from('Projects')
              .select('project_id, title, projectdata')
              .eq('contractee_id', contracteeId)
              .eq('status', 'pending')
              .filter('projectdata->>hiring_type', 'eq', 'direct_hire');
          
          if (pendingHireRequests.isNotEmpty) {
            final projectTitle = pendingHireRequests.first['title'] ?? 'Untitled';
            ConTrustSnackBar.info(
              context,
              'You already have a pending hire request project: "$projectTitle". Wait for contractor responses before posting a new project.',
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

          final actionTaken = await ProjectModal.show(
            context: context,
            contracteeId: contracteeId,
            titleController: titleController,
            constructionTypeController: typeController,
            minBudgetController: minBudgetController,
            maxBudgetController: maxBudgetController,
            locationController: locationController,
            descriptionController: descriptionController,
            bidTimeController: bidTimeController,
            onRefresh: _loadProjectsOnly,
          );
          if (actionTaken) {
            ConTrustSnackBar.success(context, 'Project posted successfully!');
            await Future.delayed(const Duration(seconds: 1));
            await _loadProjectsOnly();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final projectsToShow = projects.isEmpty ? [HomePageBuilder.getPlaceholderProject()] : projects;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 15, 
          vertical: isMobile ? 8 : 3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isMobile ? 20 : 30),
            Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh, color: Colors.amber[700], size: 20),
                  label: Text(
                    "Refresh",
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
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
            // Active Projects and Bids in same row
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : isMobile
                    ? Column(
                        children: [
                          // Mobile: Stack vertically
                          HomePageBuilder.buildActiveProjectsContainer(
                            context: context,
                            onPostProject: _postProject,
                            projectContent: ListView.builder(
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

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: ProjectView(
                                    project: project,
                                    projectId: projectId,
                                    highestBid: highestBid,
                                    duration: project['duration'] ?? 0,
                                    createdAt: DateTime.parse(project['created_at'].toString()).toLocal(),
                                    onTap: () {},
                                    handleFinalizeBidding: (projectId) {
                                      return BiddingService().finalizeBidding(projectId);
                                    },
                                    onUpdateProject: (projectId) => _handleUpdateProject(projectId, project),
                                    onCancelProject: (projectId, reason) => _handleCancelProject(projectId, reason),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bids Container for mobile
                          if (projects.isNotEmpty)
                            ...projects.map((project) {
                              final projectId = project['project_id'].toString();
                              final projectTitle = project['project_title'] ?? 'Untitled Project';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
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
                                        Icon(Icons.format_list_bulleted, color: Colors.amber[700], size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Bids for $projectTitle",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    HomePageBuilder.buildBidsContainer(
                                      context: context,
                                      projectId: projectId,
                                      acceptBidding: _loadAcceptBidding,
                                      projectStatus: project['status'],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Desktop: Active Projects Container
                          Expanded(
                            flex: 3,
                            child: HomePageBuilder.buildActiveProjectsContainer(
                              context: context,
                              onPostProject: _postProject,
                              projectContent: ListView.builder(
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

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: ProjectView(
                                      project: project,
                                      projectId: projectId,
                                      highestBid: highestBid,
                                      duration: project['duration'] ?? 0,
                                      createdAt: DateTime.parse(project['created_at'].toString()).toLocal(),
                                      onTap: () {},
                                      handleFinalizeBidding: (projectId) {
                                        return BiddingService().finalizeBidding(projectId);
                                      },
                                      onUpdateProject: (projectId) => _handleUpdateProject(projectId, project),
                                      onCancelProject: (projectId, reason) => _handleCancelProject(projectId, reason),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Desktop: Bids Container
                          Expanded(
                            flex: 2,
                            child: Container(
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
                                  if (projects.isNotEmpty)
                                    ...projects.map((project) {
                                      final projectId = project['project_id'].toString();
                                      final projectTitle = project['project_title'] ?? 'Untitled Project';
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.format_list_bulleted, color: Colors.amber[700], size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Bids for $projectTitle",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          HomePageBuilder.buildBidsContainer(
                                            context: context,
                                            projectId: projectId,
                                            acceptBidding: _loadAcceptBidding,
                                            projectStatus: project['status'],
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
            const SizedBox(height: 20),
            HomePageBuilder.buildStatsSection(
              context: context,
              projects: projects,
              contractors: contractors,
            ),
          ],
        ),
      ),
    );
  }
}

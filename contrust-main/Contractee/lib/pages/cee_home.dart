// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
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
import 'package:contractee/build/buildceeprofile.dart';
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
  bool isPostingProject = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
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

    void debouncedLoadData() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadData();
        }
      });
    }

    realtimeService.subscribeToNotifications(
      userId: currentUser.id,
      onUpdate: debouncedLoadData,
    );

    realtimeService.subscribeToContracteeProjects(
      userId: currentUser.id,
      onUpdate: debouncedLoadData,
    );
    realtimeService.subscribeToContracteeBids(
      userId: currentUser.id,
      onUpdate: debouncedLoadData,
    );
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
      List<Map<String, dynamic>> fetchedProjects = [];
      Map<String, double> fetchedHighestBids = {};
      String? projectTypeForSuggestion;
      
      if (supabase.auth.currentUser != null) {
        fetchedProjects = await FetchService().fetchUserProjects();
        fetchedHighestBids = await BiddingService().getProjectHighestBids();

        if (fetchedProjects.isNotEmpty) {
          Map<String, dynamic>? activeProject;
          
          try {
            activeProject = fetchedProjects.firstWhere(
              (p) => ['active', 'awaiting_contract', 'awaiting_agreement', 'awaiting_signature', 'pending'].contains(p['status']?.toString().toLowerCase()),
            );
          } catch (e) {
            if (fetchedProjects.isNotEmpty) {
              activeProject = fetchedProjects.first;
            }
          }
          
          if (activeProject != null && activeProject.isNotEmpty) {
            projectTypeForSuggestion = activeProject['type']?.toString();
          }
        }
      }
      
      List<Map<String, dynamic>> normalizeContractors(List<Map<String, dynamic>> raw) {
        return raw.map((contractor) {
          final normalized = Map<String, dynamic>.from(contractor);
          final rawRating = normalized['rating'];
          double ratingValue;
          if (rawRating is num) {
            ratingValue = rawRating.toDouble();
          } else if (rawRating is String) {
            ratingValue = double.tryParse(rawRating) ?? 0.0;
          } else {
            ratingValue = 0.0;
          }
          normalized['rating'] = ratingValue;
          return normalized;
        }).toList();
      }

      final fetchedContractorsRaw = await FetchService().fetchContractors(
        projectType: projectTypeForSuggestion,
      );

      var fetchedContractors = normalizeContractors(fetchedContractorsRaw);

      final usedProjectType = projectTypeForSuggestion != null &&
          projectTypeForSuggestion.trim().isNotEmpty;

      if (usedProjectType && fetchedContractors.isEmpty) {
        final fallbackContractorsRaw = await FetchService().fetchContractors();
        fetchedContractors = normalizeContractors(fallbackContractorsRaw);
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
        await _loadData();
        ConTrustSnackBar.success(context, 'The bid has been accepted successfully!');
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Something went wrong while accepting the bid.');
      }
    }
  }

  Future<void> _loadRejectBidding(String projectId, String bidId, {String? reason}) async {
    try {
      await BiddingService().rejectBid(bidId, projectId: projectId, reason: reason);
      if (mounted) {
        ConTrustSnackBar.success(context, 'The bid has been declined successfully!');
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Something went wrong while declining the bid.');
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
          onRefresh: () => _loadData(),
          initialStartDate: projectData['start_date'],
        );
        if (actionTaken) {
          ConTrustSnackBar.success(context, 'Project updated successfully!');
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
      await ProjectService().cancelProject(
        projectId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {

        
        try {
          final projectData = await FetchService().fetchProjectDetails(projectId);
          if (projectData != null) {
            final status = projectData['status'] as String?;
            if (status == 'cancellation_requested_by_contractee') {
              ConTrustSnackBar.info(context, 'Cancellation request sent to contractor. Waiting for approval.');
            } else if (status == 'cancelled') {
              ConTrustSnackBar.success(context, 'The project has been cancelled successfully.');
            }
          }
        } catch (_) {
          ConTrustSnackBar.success(context, 'The project has been cancelled successfully.');
        }
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Failed to cancel project. Please try again.');
      }
    }
  }


  void _postProject() {
    if (isPostingProject) return; // Prevent multiple clicks
    
    CheckUserLogin.isLoggedIn(
      context: context,
      onAuthenticated: () async {
        setState(() => isPostingProject = true);
        final contracteeId = supabase.auth.currentUser?.id;
        if (contracteeId != null) {
          try {
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
            onRefresh: () => _loadData(), 
          );
          if (actionTaken) {
            ConTrustSnackBar.success(context, 'Project posted successfully!');
            }
          } finally {
            if (mounted) {
              setState(() => isPostingProject = false);
            }
          }
        }
      },
    );
  }

  void _handleCompletedProjectsClick() {
    HomePageBuilder.showCompletedProjectsSelector(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text('Loading home...'),
          ],
        ),
      );
    }

    final activeProjects = projects.where((project) {
      final status = (project['status']?.toString().toLowerCase() ?? '');
      return status != 'completed' && status != 'ended';
    }).toList();

    final projectsToShow = activeProjects.isEmpty
        ? [HomePageBuilder.getPlaceholderProject()]
        : activeProjects;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.amber,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CeeProfileBuildMethods.buildStickyHeader('Home'),
          SliverToBoxAdapter(
            child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 15, 
              vertical: isMobile ? 8 : 3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isMobile ? 20 : 20),
                isMobile
                    ? Column(
                        children: [
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
                          const SizedBox(height: 20),
                          HomePageBuilder.buildActiveProjectsContainer(
                            context: context,
                            onPostProject: _postProject,
                            isPostingProject: isPostingProject,
                            projectContent: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: projectsToShow.length,
                              itemBuilder: (context, index) {
                                final project = projectsToShow[index];

                                final projectId = project['project_id']?.toString() ?? '';
                                final highestBid = projectId.isNotEmpty ? (highestBids[projectId] ?? 0.0) : 0.0;
                                final createdAt = project['created_at'] != null 
                                    ? DateTime.parse(project['created_at'].toString()).toLocal()
                                    : DateTime.now();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: ProjectView(
                                    project: project,
                                    projectId: projectId,
                                    highestBid: highestBid,
                                    duration: project['duration'] ?? 0,
                                    createdAt: createdAt,
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
                          if (activeProjects.isNotEmpty)
                            ...activeProjects.map((project) {
                              final projectId = project['project_id'].toString();
                              final projectTitle = project['title'] ?? 'Untitled Project';
                              final projectData = project['projectdata'] as Map<String, dynamic>?;
                              final hiringType = projectData?['hiring_type'] ?? 'bidding';
                              final isDirectHire = hiringType == 'direct_hire';
                              
                              return Column(
                                children: [
                                  Container(
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
                                            Icon(
                                              isDirectHire ? Icons.person_add : Icons.format_list_bulleted,
                                              color: Colors.amber[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                isDirectHire 
                                                    ? "Hiring Request Sent To"
                                                    : "Bids for $projectTitle",
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
                                        isDirectHire
                                            ? HomePageBuilder.buildHiringRequestsContainer(
                                                context: context,
                                                projectId: projectId,
                                              )
                                            : HomePageBuilder.buildBidsContainer(
                                                context: context,
                                                projectId: projectId,
                                                acceptBidding: _loadAcceptBidding,
                                                rejectBidding: _loadRejectBidding,
                                                projectStatus: project['status'],
                                              ),
                                      ],
                                    ),
                                  ),
                                  HomePageBuilder.buildCurrentContractorContainer(
                                    context: context,
                                    projectId: projectId,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).take(1)
                          else
                            Column(
                              children: [
                                HomePageBuilder.buildHiringBidsEmptyStateContainer(
                                  context: context,
                                  projects: activeProjects,
                                  acceptBidding: _loadAcceptBidding,
                                  rejectBidding: _loadRejectBidding,
                                ),
                                const SizedBox(height: 16),
                                HomePageBuilder.buildCurrentContractorContainer(
                                  context: context,
                                  projectId: '',
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          HomePageBuilder.buildStatsSection(
                            context: context,
                            projects: projects,
                            contractors: contractors,
                            onCompletedProjectsClick: _handleCompletedProjectsClick,
                            ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                const SizedBox(height: 20),
                                HomePageBuilder.buildActiveProjectsContainer(
                                  context: context,
                                  onPostProject: _postProject,
                                  isPostingProject: isPostingProject,
                                  projectContent: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: projectsToShow.length,
                                    itemBuilder: (context, index) {
                                      final project = projectsToShow[index];

                                      final projectId = project['project_id']?.toString() ?? '';
                                      final highestBid = projectId.isNotEmpty ? (highestBids[projectId] ?? 0.0) : 0.0;
                                      final createdAt = project['created_at'] != null 
                                          ? DateTime.parse(project['created_at'].toString()).toLocal()
                                          : DateTime.now();

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: ProjectView(
                                          project: project,
                                          projectId: projectId,
                                          highestBid: highestBid,
                                          duration: project['duration'] ?? 0,
                                          createdAt: createdAt,
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HomePageBuilder.buildStatsSection(
                                  context: context,
                                  projects: projects,
                                  contractors: contractors,
                                  onCompletedProjectsClick: _handleCompletedProjectsClick,
                                ),
                                const SizedBox(height: 20),
                                HomePageBuilder.buildHiringBidsEmptyStateContainer(
                                  context: context,
                                  projects: activeProjects,
                                  acceptBidding: _loadAcceptBidding,
                                  rejectBidding: _loadRejectBidding,
                                ),
                                const SizedBox(height: 20),
                                if (activeProjects.isNotEmpty)
                                  ...activeProjects.map((project) {
                                    final projectId = project['project_id'].toString();
                                    return HomePageBuilder.buildCurrentContractorContainer(
                                      context: context,
                                      projectId: projectId,
                                    );
                                  }).take(1)
                                else
                                  HomePageBuilder.buildCurrentContractorContainer(
                                    context: context,
                                    projectId: '',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

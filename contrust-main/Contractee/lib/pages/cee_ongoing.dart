// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/build/buildongoing.dart';
import 'package:contractee/pages/cee_messages.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CeeOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CeeOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CeeOngoingProjectScreen> createState() => _CeeOngoingProjectScreenState();
}

class _CeeOngoingProjectScreenState extends State<CeeOngoingProjectScreen> {
  final TextEditingController reportController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController costNoteController = TextEditingController();
  final TextEditingController progressController = TextEditingController();

  bool isEditing = false;
  String selectedTab = 'Tasks'; 

  final _fetchService = FetchService();
  final supabase = Supabase.instance.client;
  String? _chatRoomId;
  bool _canChat = false;
  Map<String, dynamic>? _contractorData;

  Map<String, dynamic>? projectData;
  List<Map<String, dynamic>> _localTasks = [];
  double _localProgress = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
    _getChatRoomId();
    _checkChatPermission();
    _loadContractorData();
  }

  @override
  void dispose() {
    reportController.dispose();
    costAmountController.dispose();
    costNoteController.dispose();
    progressController.dispose();
    super.dispose();
  }

  Future<void> _getChatRoomId() async {
    try {
      final chatRoomId = await _fetchService.fetchChatRoomId(widget.projectId);
      setState(() {
        _chatRoomId = chatRoomId;
      });
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error getting chatroom_id:');
    }
  }

  Future<void> _checkChatPermission() async {
    try {
      final project = await _fetchService.fetchProjectDetails(widget.projectId);
      if (project != null) {
        final contractorId = project['contractor_id'];
        final contracteeId = supabase.auth.currentUser?.id;
        if (contractorId != null && contracteeId != null) {
          final canChat = await functionConstraint(contractorId, contracteeId);
          setState(() {
            _canChat = canChat;
          });
        }
      }
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error checking chat permission: ');
    }
  }

  Future<void> _loadContractorData() async {
    try {
      final project = await _fetchService.fetchProjectDetails(widget.projectId);
      if (project != null) {
        final contractorId = project['contractor_id'];
        if (contractorId != null) {
          final contractorData = await supabase
              .from('Contractor')
              .select('firm_name, profile_photo')
              .eq('contractor_id', contractorId)
              .single();
          setState(() {
            _contractorData = contractorData;
          });
        }
      }
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error loading contractor data: ');
    }
  }

  void loadData() async {
    try {
      setState(() => isLoading = true);
      
      final data = await _fetchService.fetchProjectDetails(widget.projectId);
      final tasks = await _fetchService.fetchProjectTasks(widget.projectId);
      
      setState(() {
        projectData = data;
        _localTasks = tasks;
        _localProgress = (data?['progress'] as num?)?.toDouble() ?? 0.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading project data. Please try again.');
      }
    }
  }

  void onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  Future<String?> createSignedPhotoUrl(String? path) async {
    if (path == null) return null;
    try {
      final response = await supabase.storage
          .from('projectphotos')
          .createSignedUrl(path, 60 * 60 * 24); // 24 hours
      return response;
    } catch (e) {
      return null;
    }
  }

  void onViewReport(Map<String, dynamic> report) {
    CeeOngoingBuildMethods.showReportDialog(context, report);
  }

  void onViewPhoto(Map<String, dynamic> photo) {
    CeeOngoingBuildMethods.showPhotoDialog(context, photo, createSignedPhotoUrl);
  }

  void onViewMaterial(Map<String, dynamic> material) {
    CeeOngoingBuildMethods.showMaterialDetailsDialog(context, material);
  }

  void _navigateToChat() {
    if (_chatRoomId == null || !_canChat) return;
    
    final project = projectData!;
           final contracteeId = project['contractee_id'] ?? '';
           final contractorId = project['contractor_id'] ?? '';
           final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
           final contractorPhoto = _contractorData?['profile_photo'] ?? '';

                                     Navigator.push(
                                       context,
                                       MaterialPageRoute(
                                         builder: (context) => MessagePageContractee(
                                           chatRoomId: _chatRoomId!,
                                           contracteeId: contracteeId,
                                           contractorId: contractorId,
                                           contractorName: contractorName,
                                           contractorProfile: contractorPhoto,
                                         ),
                                       ),
                                     );
                                   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber,))
          : projectData == null
              ? const Center(child: Text('Project not found.'))
              : _buildResponsiveContent(),
    );
  }

  Widget _buildResponsiveContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    if (isMobile) {
      return _buildMobileContent();
    } else {
      return _buildDesktopContent();
    }
  }

  Widget _buildMobileContent() {
    final project = projectData!;
           final projectTitle = project['title'] ?? 'Project';
    final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
           final address = project['location'] ?? '';
           final startDate = project['start_date'] ?? '';
           final estimatedCompletion = project['estimated_completion'] ?? '';

          return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: CeeOngoingBuildMethods.buildMobileLayout(
        projectTitle: projectTitle,
        clientName: contractorName,
        address: address,
        startDate: startDate,
        estimatedCompletion: estimatedCompletion,
        progress: _localProgress,
        selectedTab: selectedTab,
        onTabChanged: onTabChanged,
        onRefresh: loadData,
        onChat: _canChat && _chatRoomId != null ? _navigateToChat : null,
        canChat: _canChat,
        tabContent: _buildTabContent(),
                                  ),
                                );
                              }

  Widget _buildDesktopContent() {
    final project = projectData!;
    final projectTitle = project['title'] ?? 'Project';
    final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
    final address = project['location'] ?? '';
    final startDate = project['start_date'] ?? '';
    final estimatedCompletion = project['estimated_completion'] ?? '';

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _getTabData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [[], [], []];
          final reports = data[0];
          final photos = data[1];
          final costs = data[2];

          return CeeOngoingBuildMethods.buildDesktopGridLayout(
            context: context,
            projectTitle: projectTitle,
            clientName: contractorName,
            address: address,
            startDate: startDate,
            estimatedCompletion: estimatedCompletion,
            progress: _localProgress,
            tasks: _localTasks,
            reports: reports,
            photos: photos,
            costs: costs,
            createSignedUrl: createSignedPhotoUrl,
            onViewReport: onViewReport,
            onViewPhoto: onViewPhoto,
            onViewMaterial: onViewMaterial,
            onRefresh: loadData,
            onChat: _canChat && _chatRoomId != null ? _navigateToChat : null,
            canChat: _canChat,
          );
        },
      ),
    );
                              }

  Widget _buildTabContent() {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: _getTabData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? [[], [], []];
        final reports = data[0];
        final photos = data[1];
        final costs = data[2];

        return CeeOngoingBuildMethods.buildTabContent(
          context: context,
          selectedTab: selectedTab,
          tasks: _localTasks,
          reports: reports,
          photos: photos,
          costs: costs,
          createSignedUrl: createSignedPhotoUrl,
          onViewReport: onViewReport,
          onViewPhoto: onViewPhoto,
          onViewMaterial: onViewMaterial,
                                  );
                                },
                              );
  }

  Future<List<List<Map<String, dynamic>>>> _getTabData() async {
    try {
      final reports = await _fetchService.fetchProjectReports(widget.projectId);
      final photos = await _fetchService.fetchProjectPhotos(widget.projectId);
      final costs = await _fetchService.fetchProjectCosts(widget.projectId);
      return [reports, photos, costs];
    } catch (e) {
      return [[], [], []];
    }
  }
}

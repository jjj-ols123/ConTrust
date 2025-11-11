// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/contractor services/cor_ongoingservices.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/buildongoing.dart';
import 'package:contractor/Screen/cor_project_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CorOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CorOngoingProjectScreen> createState() =>
      _CorOngoingProjectScreenState();
}

class _CorOngoingProjectScreenState extends State<CorOngoingProjectScreen> {
  final TextEditingController reportController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController costNoteController = TextEditingController();

  bool isEditing = false;
  String selectedTab = 'Tasks';

  final ongoingService = CorOngoingService();

  Map<String, dynamic>? projectData;
  List<Map<String, dynamic>> _localTasks = [];
  String? contractorId;
  String? _contractorFirmName;
  Stream<Map<String, dynamic>>? _projectStream;
  final List<StreamSubscription> _subscriptions = [];
  StreamController<Map<String, dynamic>>? _controller;
  final Map<String, String?> _photoUrlCache = {};
  Timer? _debounceTimer;
  bool _isRetryingRealtime = false;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _disposeRealtime();
    contractorId = Supabase.instance.client.auth.currentUser?.id;
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _projectStream = _controller!.stream;
    _attachRealtimeListeners();
    _emitAggregatedData();
    _loadContractorFirmName();
  }

  Future<void> _loadContractorFirmName() async {
    if (contractorId == null) return;
    try {
      final contractor = await Supabase.instance.client
          .from('Contractor')
          .select('firm_name')
          .eq('contractor_id', contractorId!)
          .maybeSingle();
      if (contractor != null && mounted) {
        setState(() {
          _contractorFirmName = contractor['firm_name'] as String?;
        });
      }
    } catch (e) {
      //
    }
  }

  Future<void> refreshProjectData({VoidCallback? onComplete}) async {
    await loadData();
    await _emitAggregatedData();
    onComplete?.call();
  }

  void _debouncedEmitAggregatedData() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _emitAggregatedData();
    });
  }

  void _attachRealtimeListeners() {
    final supabase = Supabase.instance.client;
    
    void safeListen(Stream stream, String tableName) {
      _subscriptions.add(
        stream.listen(
          (_) => _debouncedEmitAggregatedData(),
          onError: (error) {
            if (mounted && !_isRetryingRealtime) {
              _isRetryingRealtime = true;
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  for (final sub in _subscriptions) {
                    sub.cancel();
                  }
                  _subscriptions.clear();
                  _isRetryingRealtime = false;
                  _attachRealtimeListeners();
                } else {
                  _isRetryingRealtime = false;
                }
              });
            }
          },
          cancelOnError: false,
        ),
      );
    }
    
    try {
      safeListen(
        supabase
            .from('Projects')
            .stream(primaryKey: ['contractor_id', 'project_id'])
            .eq('project_id', widget.projectId),
        'Projects',
      );
      safeListen(
        supabase
            .from('ProjectTasks')
            .stream(primaryKey: ['task_id'])
            .eq('project_id', widget.projectId),
        'ProjectTasks',
      );
      safeListen(
        supabase
            .from('ProjectReports')
            .stream(primaryKey: ['report_id'])
            .eq('project_id', widget.projectId),
        'ProjectReports',
      );
      safeListen(
        supabase
            .from('ProjectPhotos')
            .stream(primaryKey: ['photo_id'])
            .eq('project_id', widget.projectId),
        'ProjectPhotos',
      );
      safeListen(
        supabase
            .from('ProjectMaterials')
            .stream(primaryKey: ['material_id'])
            .eq('project_id', widget.projectId),
        'ProjectMaterials',
      );
      safeListen(
        supabase
            .from('Contracts')
            .stream(primaryKey: ['contract_id'])
            .eq('project_id', widget.projectId),
        'Contracts',
      );
    } catch (e) {
      //
    }
  }

  Future<void> _emitAggregatedData() async {
    try {
      final data = await ongoingService.loadProjectData(
        widget.projectId,
        contractorId: contractorId,
      );
      final contractId = data['projectDetails']['contract_id'];
      if (contractId != null) {
        final contract = await ongoingService.getContractById(contractId);
        data['contracts'] = contract != null ? [contract] : [];
      } else {
        data['contracts'] = [];
      }
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
    } catch (e) {
      //
    }
  }

  Future<void> switchProject() async {
    try {

      if (projectData == null) return;
      contractorId ??= projectData!['projectDetails']?['contractor_id'];
      if (contractorId == null) return;

      final activeProjects = await FetchService().fetchContractorActiveProjects(contractorId!);

      if (activeProjects.isEmpty) {
        ConTrustSnackBar.info(context, 'No active projects found. You can only switch between active projects.');
        return;
      }

      if (activeProjects.length == 1) {
        ConTrustSnackBar.warning(context, 'You only have one active project.');
        return;
      }

      final selectedProjectId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Switch Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: activeProjects.length,
                      itemBuilder: (context, index) {
                        final project = activeProjects[index];
                        final isCurrentProject = project['project_id'] == widget.projectId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isCurrentProject ? Colors.amber.shade50 : null,
                          child: ListTile(
                            selected: isCurrentProject,
                            title: Text(
                              project['title'] ?? 'Untitled Project',
                              style: TextStyle(
                                fontWeight: isCurrentProject ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(isCurrentProject 
                              ? 'Current Project • ${project['status'] ?? 'N/A'}' 
                              : 'Status: ${project['status'] ?? 'N/A'}'),
                            leading: isCurrentProject 
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.folder, color: Colors.amber.shade700),
                            trailing: isCurrentProject 
                              ? null 
                              : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade700),
                            onTap: isCurrentProject 
                              ? null 
                              : () {
                                  Navigator.of(dialogContext).pop(project['project_id']);
                                },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      );

      if (selectedProjectId != null && selectedProjectId != widget.projectId) {
        context.go('/project-management/$selectedProjectId');
      }
    } catch (e) {
      ConTrustSnackBar.error(context, 'Failed to switch project');
    }
  }

  Future<void> loadData() async {
    try {
      contractorId ??= Supabase.instance.client.auth.currentUser?.id;

      final data = await ongoingService.loadProjectData(
        widget.projectId,
        contractorId: contractorId,
      );

      final contractId = data['projectDetails']['contract_id'];
      if (contractId != null) {
        final contract = await ongoingService.getContractById(contractId);
        data['contracts'] = contract != null ? [contract] : [];
      } else {
        data['contracts'] = [];
      }

      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(
            context, 'Error loading project data. Please try again. $e');
      }
    }
  }

  void onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  Future<void> addReport() async {
    await OngoingBuildMethods.showAddReportDialog(
      context: context,
      controller: reportController,
      onAdd: () async {
        await ongoingService.addReport(
          projectId: widget.projectId,
          content: reportController.text.trim(),
          context: context,
          onSuccess: () {
            reportController.clear();
          },
        );
      },
    );
  }

  Future<void> addTask() async {
    await OngoingBuildMethods.showAddTaskDialog(
      context: context,
      onAdd: (taskList) async {
        for (final taskData in taskList) {
          final task = taskData['task'] as String;
          final expectFinish = taskData['expect_finish'] as DateTime?;
          await ongoingService.addTask(
            projectId: widget.projectId,
            task: task,
            context: context,
            expectFinish: expectFinish,
            onSuccess: () {
            },
          );
        }
      },
    );
  }

  Future<void> pickImage() async {
    await ongoingService.uploadPhoto(
      projectId: widget.projectId,
      context: context,
      onSuccess: () {
      },
    );
  }

  void updateTaskStatus(String taskId, bool done) async {
    setState(() {
      final taskIndex = _localTasks.indexWhere(
        (task) => task['task_id'].toString() == taskId,
      );
      if (taskIndex != -1) {
        _localTasks[taskIndex] = {..._localTasks[taskIndex], 'done': done};
      }
    });

    try {
      await ongoingService.updateTaskStatus(
        projectId: widget.projectId,
        taskId: taskId,
        done: done,
        allTasks: _localTasks,
        context: context,
      );
    } catch (e) {
      setState(() {
        final taskIndex = _localTasks.indexWhere(
          (task) => task['task_id'].toString() == taskId,
        );
        if (taskIndex != -1) {
          _localTasks[taskIndex] = {..._localTasks[taskIndex], 'done': !done};
        }
      });
    }
  }

  Future<String?> createSignedPhotoUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    
    // Check cache first - return completed future if cached
    if (_photoUrlCache.containsKey(path)) {
      return Future.value(_photoUrlCache[path]);
    }
    
    // Fetch and cache the URL
    final url = await ongoingService.createSignedPhotoUrl(path);
    if (url != null) {
      _photoUrlCache[path] = url;
    }
    return url;
  }

  Future<void> deleteTask(String taskId) async {
    await ongoingService.deleteTask(
      taskId: taskId,
      context: context,
      onSuccess: () {
      },
    );
  }

  Future<void> deleteReport(String reportId) async {
    await ongoingService.deleteReport(
      reportId: reportId,
      context: context,
      onSuccess: () {
      },
    );
  }

  Future<void> deletePhoto(String photoId) async {
    final photo = projectData?['photos']?.firstWhere(
      (p) => p['photo_id']?.toString() == photoId,
      orElse: () => null,
    );
    if (photo != null && photo['photo_url'] != null) {
      _photoUrlCache.remove(photo['photo_url']);
    }
    
    await ongoingService.deletePhoto(
      photoId: photoId,
      context: context,
      onSuccess: () {
      },
    );
  }

  Future<void> deleteCost(String materialId) async {
    await ongoingService.deleteCost(
      materialId: materialId,
      context: context,
      onSuccess: () {
      },
    );
  }

  @override
  void dispose() {
    _disposeRealtime();
    reportController.dispose();
    costAmountController.dispose();
    costNoteController.dispose();
    super.dispose();
  }

  void onViewReport(Map<String, dynamic> report) {
    OngoingBuildMethods.showReportDialog(context, report);
  }

  void onViewPhoto(Map<String, dynamic> photo) {
    OngoingBuildMethods.showPhotoDialog(context, photo, createSignedPhotoUrl);
  }

  void goToMaterials() {
    final contractorId = Supabase.instance.client.auth.currentUser?.id;
    if (contractorId != null) {
      context.go('/project-management/${widget.projectId}/materials');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _projectStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
              ),
            );
          }

          if (snapshot.hasError) {
            // Check if it's a RealtimeSubscribeException - these are often recoverable
            final error = snapshot.error;
            final isRealtimeError = error.toString().contains('RealtimeSubscribeException');
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isRealtimeError ? Colors.orange.shade300 : Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRealtimeError 
                        ? 'Connection issue - retrying...' 
                        : 'Error loading project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeStreams();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Project not found.'),
            );
          }

          projectData = snapshot.data;
          _localTasks = List<Map<String, dynamic>>.from(projectData!['tasks'] ?? []);

          return _buildResponsiveContent();
        },
      ),
    );
  }

  void _disposeRealtime() {
    _debounceTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _controller?.close();
    _controller = null;
  }

  Widget _buildResponsiveContent() {
    return _buildDesktopContent();
  }


  Widget _buildDesktopContent() {
    return RefreshIndicator(
      onRefresh: () async {
        loadData();
        await _loadContractorFirmName();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: CorProjectDashboard(
            projectId: widget.projectId,
            projectData: projectData,
            contractorFirmName: _contractorFirmName,
            ongoingService: ongoingService,
            createSignedPhotoUrl: createSignedPhotoUrl,
          ),
        ),
      ),
    );
  }
}

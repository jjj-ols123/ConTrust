// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/both%20services/be_fetchservice.dart';
import 'package:backend/services/contractor services/cor_ongoingservices.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/build/buildongoing.dart';
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
  final TextEditingController progressController = TextEditingController();

  bool isEditing = false;
  String selectedTab = 'Tasks';

  final ongoingService = CorOngoingService();

  Map<String, dynamic>? projectData;
  List<Map<String, dynamic>> _localTasks = [];
  double _localProgress = 0.0;
  bool isLoading = true;
  String? contractorId;
  Stream<Map<String, dynamic>>? _projectStream;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    contractorId = Supabase.instance.client.auth.currentUser?.id;
    _projectStream = _createProjectStream();
  }

  Stream<Map<String, dynamic>> _createProjectStream() {
    return FetchService().streamProjectData(widget.projectId).asyncMap((projectDetails) async {
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

        return data;
      } catch (e) {
        throw Exception('Failed to load project data: $e');
      }
    });
  }

  Future<void> switchProject() async {
    try {

      if (projectData == null) return;
      contractorId ??= projectData!['projectDetails']?['contractor_id'];
      if (contractorId == null) return;

      final activeProjects = await FetchService().fetchContractorActiveProjects(contractorId!);

      if (activeProjects.isEmpty) {
        ConTrustSnackBar.error(context, 'No active projects found!');
        return;
      }

      if (activeProjects.length == 1) {
        ConTrustSnackBar.warning(context, 'You only have one active project.');
        return;
      }

      final selectedProjectId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Switch Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
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
      );

      if (selectedProjectId != null && selectedProjectId != widget.projectId) {
        context.go('/project-management', extra: selectedProjectId);
      }
    } catch (e) {
      ConTrustSnackBar.error(context, 'Failed to switch project');
    }
  }

  void loadData() async {
  try {
    setState(() => isLoading = true);

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

    setState(() {
      projectData = data;
      _localTasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
      _localProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
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

  void addReport() async {
    OngoingBuildMethods.showAddReportDialog(
      context: context,
      controller: reportController,
      onAdd: () async {
        await ongoingService.addReport(
          projectId: widget.projectId,
          content: reportController.text.trim(),
          context: context,
          onSuccess: () {
            reportController.clear();
            loadData();
          },
        );
      },
    );
  }

  void addTask() async {
    OngoingBuildMethods.showAddTaskDialog(
      context: context,
      onAdd: (tasks) async {
        for (final task in tasks) {
          await ongoingService.addTask(
            projectId: widget.projectId,
            task: task,
            context: context,
            onSuccess: () {
              loadData();
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
      onSuccess: loadData,
    );
  }

  void updateTaskStatus(String taskId, bool done) async {
    setState(() {
      final taskIndex = _localTasks.indexWhere(
        (task) => task['task_id'].toString() == taskId,
      );
      if (taskIndex != -1) {
        _localTasks[taskIndex] = {..._localTasks[taskIndex], 'done': done};
        final completedTasks =
            _localTasks.where((task) => task['done'] == true).length;
        final totalTasks = _localTasks.length;
        _localProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
      }
    });

    try {
      await ongoingService.updateTaskStatus(
        projectId: widget.projectId,
        taskId: taskId,
        done: done,
        allTasks: _localTasks,
        context: context,
        onProgressUpdate: (newProgress) {
          setState(() => _localProgress = newProgress);
        },
      );
    } catch (e) {
      setState(() {
        final taskIndex = _localTasks.indexWhere(
          (task) => task['task_id'].toString() == taskId,
        );
        if (taskIndex != -1) {
          _localTasks[taskIndex] = {..._localTasks[taskIndex], 'done': !done};
          final completedTasks =
              _localTasks.where((task) => task['done'] == true).length;
          final totalTasks = _localTasks.length;
          _localProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
        }
      });
    }
  }

  Future<String?> createSignedPhotoUrl(String? path) async {
    return await ongoingService.createSignedPhotoUrl(path);
  }

  Future<void> deleteTask(String taskId) async {
    await ongoingService.deleteTask(
      taskId: taskId,
      context: context,
      onSuccess: loadData,
    );
  }

  Future<void> deleteReport(String reportId) async {
    await ongoingService.deleteReport(
      reportId: reportId,
      context: context,
      onSuccess: loadData,
    );
  }

  Future<void> deletePhoto(String photoId) async {
    await ongoingService.deletePhoto(
      photoId: photoId,
      context: context,
      onSuccess: loadData,
    );
  }

  Future<void> deleteCost(String materialId) async {
    await ongoingService.deleteCost(
      materialId: materialId,
      context: context,
      onSuccess: loadData,
    );
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
      context.go('/materials', extra: {'projectId': widget.projectId});
    }
  }

  Map<String, String?> _extractContractInfo(List<Map<String, dynamic>> contracts) {
    if (contracts.isEmpty) return {};

    final contract = contracts.first;
    final fieldValues = contract['field_values'] as Map<String, dynamic>? ?? {};

    final contractee =
        contract['contractee'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final clientName = fieldValues['Contractee.FirstName'] != null &&
            fieldValues['Contractee.LastName'] != null
        ? '${fieldValues['Contractee.FirstName']} ${fieldValues['Contractee.LastName']}'
        : contractee['full_name'] ?? '';
    final estimateDate = fieldValues['Project.CompletionDate'] ?? '';

    return {
      'clientName': clientName,
      'estimateDate': estimateDate,
    };
  }

  bool _isCustomContract() {
    final contractsRaw = projectData?['contracts'];
    if (contractsRaw is List) {
      final contracts = contractsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return contracts.any((contract) =>
          (contract['contract_type_id']?.toString() ?? '') ==
          CorOngoingService.kCustomContractTypeId);
    }
    return false;
  }

  void _editCompletion() {
    final currentCompletion = projectData?['projectDetails']
        ?['estimated_completion']; 
    DateTime? completionDate;
    if (currentCompletion != null) {
      try {
        completionDate = DateTime.parse(currentCompletion).toLocal();
      } catch (_) {
        completionDate = null;
      }
    }

    OngoingBuildMethods.showEditCompletionDialog(
      context: context,
      currentCompletion: completionDate,
      onSave: (selectedDate) async {
        await ongoingService.updateEstimatedCompletion(
          projectId: widget.projectId,
          estimatedCompletion: selectedDate,
          context: context,
          onSuccess: loadData,
        );
      },
    );
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading project',
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

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                projectData = snapshot.data;
                _localTasks = List<Map<String, dynamic>>.from(projectData!['tasks'] ?? []);
                _localProgress = (projectData!['progress'] as num?)?.toDouble() ?? 0.0;
                isLoading = false;
              });
            }
          });

          return _buildResponsiveContent();
        },
      ),
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
    final project = projectData!['projectDetails'] as Map<String, dynamic>;
    final reports = projectData!['reports'] as List<Map<String, dynamic>>;
    final photos = projectData!['photos'] as List<Map<String, dynamic>>;
    final costs = projectData!['costs'] as List<Map<String, dynamic>>;
    final contractsRaw = projectData!['contracts'];
    final contracts = contractsRaw is List ? contractsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];

    final projectTitle = project['title'] ?? 'Project';
    final clientName = project['full_name'] ?? 'Client';
    final address = project['location'] ?? '';
    
    String startDate = project['start_date'] ?? '';
    if (startDate.isEmpty && _isCustomContract() && contracts.isNotEmpty) {
      try {
        final contract = contracts.first;
        final fieldValues = contract['field_values'];
        if (fieldValues != null && fieldValues is Map) {
          final startDateValue = fieldValues['Project.StartDate'];
          if (startDateValue != null && startDateValue.toString().isNotEmpty) {
            startDate = startDateValue.toString();
          }
        }
      } catch (_) {}
    }

    final contractInfo = _extractContractInfo(contracts);

    final int? duration = project['duration'] != null
        ? (project['duration'] is int
            ? project['duration'] as int
            : int.tryParse(project['duration'].toString()))
        : null;

    final estimatedCompletion = _isCustomContract() 
        ? (project['estimated_completion'] ?? '') 
        : (contractInfo['estimateDate'] ?? project['estimated_completion'] ?? '');

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: OngoingBuildMethods.buildMobileLayout(
        projectTitle: projectTitle,
        clientName: contractInfo['clientName'] ?? clientName,
        address: address,
        startDate: startDate,
        estimatedCompletion: estimatedCompletion,
        duration: duration,
        isCustomContract: _isCustomContract(),
        progress: _localProgress,
        selectedTab: selectedTab,
        tasks: _localTasks,
        reports: reports,
        photos: photos,
        onTabChanged: onTabChanged,
        onRefresh: loadData,
        onEditCompletion:
            _isCustomContract() ? _editCompletion : null,
        onSwitchProject: switchProject,
        tabContent: OngoingBuildMethods.buildTabContent(
          context: context,
          selectedTab: selectedTab,
          tasks: _localTasks,
          reports: reports,
          photos: photos,
          costs: costs,
          onUpdateTaskStatus: updateTaskStatus,
          onDeleteTask: deleteTask,
          onDeleteReport: deleteReport,
          onDeletePhoto: deletePhoto,
          onDeleteCost: deleteCost,
          createSignedUrl: createSignedPhotoUrl,
          onAddTask: addTask,
          onAddReport: addReport,
          onAddPhoto: pickImage,
          onGoToMaterials: goToMaterials,
          onViewReport: onViewReport,
          onViewPhoto: onViewPhoto,
        ),
      ),
    );
  }

  Widget _buildDesktopContent() {
    final project = projectData!['projectDetails'] as Map<String, dynamic>;
    final reports = projectData!['reports'] as List<Map<String, dynamic>>;
    final photos = projectData!['photos'] as List<Map<String, dynamic>>;
    final costs = projectData!['costs'] as List<Map<String, dynamic>>;
    final contractsRaw = projectData!['contracts'];
    final contracts = contractsRaw is List ? contractsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];

    final projectTitle = project['title'] ?? 'Project';
    final clientName = project['full_name'] ?? 'Client';
    final address = project['location'] ?? '';
    
    String startDate = project['start_date'] ?? '';
    if (startDate.isEmpty && _isCustomContract() && contracts.isNotEmpty) {
      try {
        final contract = contracts.first;
        final fieldValues = contract['field_values'];
        if (fieldValues != null && fieldValues is Map) {
          final startDateValue = fieldValues['Project.StartDate'];
          if (startDateValue != null && startDateValue.toString().isNotEmpty) {
            startDate = startDateValue.toString();
          }
        }
      } catch (_) {}
    }

    final contractInfo = _extractContractInfo(contracts);

    final int? duration = project['duration'] != null
        ? (project['duration'] is int
            ? project['duration'] as int
            : int.tryParse(project['duration'].toString()))
        : null;

    final estimatedCompletion = _isCustomContract() 
        ? (project['estimated_completion'] ?? '') 
        : (contractInfo['estimateDate'] ?? project['estimated_completion'] ?? '');

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: OngoingBuildMethods.buildDesktopGridLayout(
        context: context,
        projectTitle: projectTitle,
        clientName: contractInfo['clientName'] ?? clientName,
        address: address,
        startDate: startDate,
        estimatedCompletion: estimatedCompletion,
        duration: duration,
        isCustomContract: _isCustomContract(),
        progress: _localProgress,
        tasks: _localTasks,
        reports: reports,
        photos: photos,
        costs: costs,
        onUpdateTaskStatus: updateTaskStatus,
        onDeleteTask: deleteTask,
        onDeleteReport: deleteReport,
        onDeletePhoto: deletePhoto,
        onDeleteCost: deleteCost,
        createSignedUrl: createSignedPhotoUrl,
        onAddTask: addTask,
        onAddReport: addReport,
        onAddPhoto: pickImage,
        onGoToMaterials: goToMaterials,
        onViewReport: onViewReport,
        onViewPhoto: onViewPhoto,
        onRefresh: loadData,
        onEditCompletion: _isCustomContract() ? _editCompletion : null,
        onSwitchProject: switchProject,
      ),
    );
  }
}

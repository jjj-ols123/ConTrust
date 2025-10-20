// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/contractor services/cor_ongoingservices.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractor/Screen/cor_product.dart';
import 'package:contractor/build/builddrawer.dart';
import 'package:contractor/build/buildongoing.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
  try {
    setState(() => isLoading = true);

    final data = await ongoingService.loadProjectData(widget.projectId);

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
          context, 'Error loading project data. Please try again.');
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

  Future<void> goToMaterials() async {
    final contractorId = Supabase.instance.client.auth.currentUser?.id;
    if (contractorId != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractorShell(
            currentPage: ContractorPage.materials,
            contractorId: contractorId,
            child: ProductPanelScreen(
              contractorId: contractorId,
              projectId: widget.projectId,
            ),
          ),
        ),
      );

      if (result == true || result == null) {
        loadData();
      }
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
        ?['estimated_completion']; // may be null
    DateTime? completionDate;
    if (currentCompletion != null) {
      try {
        completionDate = DateTime.parse(currentCompletion);
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.amber,
            ))
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
    final project = projectData!['projectDetails'] as Map<String, dynamic>;
    final reports = projectData!['reports'] as List<Map<String, dynamic>>;
    final photos = projectData!['photos'] as List<Map<String, dynamic>>;
    final costs = projectData!['costs'] as List<Map<String, dynamic>>;
    final contractsRaw = projectData!['contracts'];
    final contracts = contractsRaw is List ? contractsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];

    final projectTitle = project['title'] ?? 'Project';
    final clientName = project['full_name'] ?? 'Client';
    final address = project['location'] ?? '';
    final startDate = project['start_date'] ?? '';

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
        onTabChanged: onTabChanged,
        onRefresh: loadData,
        onEditCompletion:
            _isCustomContract() ? _editCompletion : null, 
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
    final startDate = project['start_date'] ?? '';

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
      ),
    );
  }
}

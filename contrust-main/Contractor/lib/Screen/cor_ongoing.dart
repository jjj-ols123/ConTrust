// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/contractor services/cor_ongoingservices.dart';
import 'package:contractor/build/buildongoing.dart';
import 'package:flutter/material.dart';

class CorOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CorOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CorOngoingProjectScreen> createState() =>
      _CorOngoingProjectScreenState();
}

class _CorOngoingProjectScreenState extends State<CorOngoingProjectScreen> {
  final TextEditingController reportController = TextEditingController();
  final TextEditingController taskController = TextEditingController();
  final TextEditingController costItemController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController costNoteController = TextEditingController();
  final TextEditingController progressController = TextEditingController();

  bool isEditing = false;
  final ongoingService = CorOngoingService();
  String selectedTab = 'Tasks'; 

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

      setState(() {
        projectData = data;
        _localTasks = data['tasks'];
        _localProgress = data['progress'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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
      controller: taskController,
      onAdd: () async {
        await ongoingService.addTask(
          projectId: widget.projectId,
          task: taskController.text.trim(),
          context: context,
          onSuccess: () {
            taskController.clear();
            loadData();
          },
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
    final project = projectData!['projectDetails'];
    final reports = projectData!['reports'] as List<Map<String, dynamic>>;
    final photos = projectData!['photos'] as List<Map<String, dynamic>>;
    final costs = projectData!['costs'] as List<Map<String, dynamic>>;

    final projectTitle = project['title'] ?? 'Project';
    final clientName = project['full_name'] ?? 'Client';
    final address = project['location'] ?? '';
    final startDate = project['start_date'] ?? '';
    final estimatedCompletion = project['estimated_completion'] ?? '';

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: OngoingBuildMethods.buildMobileLayout(
        projectTitle: projectTitle,
        clientName: clientName,
        address: address,
        startDate: startDate,
        estimatedCompletion: estimatedCompletion,
        progress: _localProgress,
        selectedTab: selectedTab,
        onTabChanged: onTabChanged,
        tabContent: OngoingBuildMethods.buildTabContent(
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
        ),
      ),
    );
  }

  Widget _buildDesktopContent() {
    final project = projectData!['projectDetails'];
    final reports = projectData!['reports'] as List<Map<String, dynamic>>;
    final photos = projectData!['photos'] as List<Map<String, dynamic>>;
    final costs = projectData!['costs'] as List<Map<String, dynamic>>;

    final projectTitle = project['title'] ?? 'Project';
    final clientName = project['full_name'] ?? 'Client';
    final address = project['location'] ?? '';
    final startDate = project['start_date'] ?? '';
    final estimatedCompletion = project['estimated_completion'] ?? '';

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: OngoingBuildMethods.buildDesktopGridLayout(
        projectTitle: projectTitle,
        clientName: clientName,
        address: address,
        startDate: startDate,
        estimatedCompletion: estimatedCompletion,
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
      ),
    );
  }
}

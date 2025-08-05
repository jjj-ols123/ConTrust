// ignore_for_file: use_build_context_synchronously

import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class CorOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CorOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CorOngoingProjectScreen> createState() =>
      _CorOngoingProjectScreenState();
}

class _CorOngoingProjectScreenState extends State<CorOngoingProjectScreen> {
  late Future<Map<String, dynamic>?> _projectFuture;
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  late Future<List<Map<String, dynamic>>> _photosFuture;
  late Future<List<Map<String, dynamic>>> _costsFuture;

  final TextEditingController reportController = TextEditingController();
  final TextEditingController taskController = TextEditingController();
  final TextEditingController costItemController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController costNoteController = TextEditingController();
  final TextEditingController progressController = TextEditingController();

  bool isEditing = false;
  final _fetchService = FetchService();
  final _projectService = ProjectService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _localTasks = [];
  double _localProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      _projectFuture = _fetchService.fetchProjectDetails(widget.projectId);
      _reportsFuture = _fetchService.fetchProjectReports(widget.projectId);
      _photosFuture = _fetchService.fetchProjectPhotos(widget.projectId);
      _costsFuture = _fetchService.fetchProjectCosts(widget.projectId);
    });

    try {
      final tasks = await _fetchService.fetchProjectTasks(widget.projectId);
      final project = await _fetchService.fetchProjectDetails(widget.projectId);

      setState(() {
        _localTasks = tasks;
        _localProgress = (project?['progress'] as num?)?.toDouble() ?? 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading local data')));
    }
  }

  void _addReport() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Progress Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reportController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter detailed progress report...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reportController.text.trim().isNotEmpty) {
                  final userId = _supabase.auth.currentUser?.id;
                  if (userId != null) {
                    await _projectService.addReportToProject(
                      projectId: widget.projectId,
                      content: reportController.text.trim(),
                      authorId: userId,
                    );
                    reportController.clear();
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Progress report added successfully!'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Report'),
            ),
          ],
        );
      },
    );
  }

  void _addTask() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              hintText: 'Enter task details',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (taskController.text.trim().isNotEmpty) {
                  await _projectService.addTaskToProject(
                    projectId: widget.projectId,
                    task: taskController.text.trim(),
                  );
                  taskController.clear();
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task added successfully!')),
                    );
                  }
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  void _addCost() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Cost Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costItemController,
                decoration: const InputDecoration(
                  hintText: 'Item name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Amount (₱)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costNoteController,
                decoration: const InputDecoration(
                  hintText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (costItemController.text.trim().isNotEmpty &&
                    costAmountController.text.trim().isNotEmpty) {
                  final amount = double.tryParse(
                    costAmountController.text.trim(),
                  );
                  if (amount != null) {
                    await _projectService.addCostToProject(
                      projectId: widget.projectId,
                      item: costItemController.text.trim(),
                      amount: amount,
                      note:
                          costNoteController.text.trim().isNotEmpty
                              ? costNoteController.text.trim()
                              : null,
                    );
                    costItemController.clear();
                    costAmountController.clear();
                    costNoteController.clear();
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cost item added successfully!'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Cost'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      try {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final userId = _supabase.auth.currentUser?.id;

        if (userId != null) {
          final fileName =
              '${widget.projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await _supabase.storage
              .from('project_photos')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );

          final photoUrl = _supabase.storage
              .from('project_photos')
              .getPublicUrl(fileName);

          await _projectService.addPhotoToProject(
            projectId: widget.projectId,
            photoUrl: photoUrl,
            uploaderId: userId,
          );

          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo uploaded successfully!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
        }
      }
    }
  }

  void _updateTaskStatus(String taskId, bool done) async {
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
      await _projectService.updateTaskStatus(taskId, done);

      await _supabase
          .from('Projects')
          .update({'progress': _localProgress})
          .eq('project_id', widget.projectId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(done ? '✓ Completed' : '○ Pending'),
            backgroundColor: done ? Colors.green : Colors.orange,
            duration: const Duration(milliseconds: 600),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update task'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateProgress() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Progress'),
          content: TextField(
            controller: progressController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter progress percentage (0-100)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final progress = double.tryParse(
                  progressController.text.trim(),
                );
                if (progress != null && progress >= 0 && progress <= 100) {
                  await _supabase
                      .from('Projects')
                      .update({'progress': progress / 100})
                      .eq('project_id', widget.projectId);
                  progressController.clear();
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Progress updated successfully!'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Ongoing Project Management"),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Project not found.'));
          }

          final project = snapshot.data!;
          final projectTitle = project['title'] ?? 'Project';
          final clientName = project['client_name'] ?? 'Client';
          final address = project['location'] ?? '';
          final startDate = project['start_date'] ?? '';
          final estimatedCompletion = project['estimated_completion'] ?? '';

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      projectTitle,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Client: $clientName',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _updateProgress,
                                icon: const Icon(Icons.edit),
                                label: const Text('Update Progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(address)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text('Start: $startDate'),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.flag,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text('Est. Completion: $estimatedCompletion'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Progress: ${(_localProgress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Tasks: ${_localTasks.where((task) => task['done'] == true).length}/${_localTasks.length} completed',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _localProgress,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _localProgress >= 1.0
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
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
                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.checklist,
                                size: 24,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Project Tasks',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: _addTask,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Task'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _localTasks.isEmpty
                              ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No tasks added yet. Add your first task to get started!',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    _localTasks
                                        .map(
                                          (task) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: CheckboxListTile(
                                              title: Text(
                                                task['task'] ?? '',
                                                style: TextStyle(
                                                  decoration:
                                                      task['done'] == true
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                  color:
                                                      task['done'] == true
                                                          ? Colors.grey[600]
                                                          : Colors.black87,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              value: task['done'] == true,
                                              onChanged: (val) {
                                                final taskId = task['task_id'];
                                                _updateTaskStatus(
                                                  taskId.toString(),
                                                  val ?? false,
                                                );
                                              },
                                              activeColor: Colors.green,
                                              checkColor: Colors.white,
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.article,
                                size: 24,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Progress Reports',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: _addReport,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _reportsFuture,
                            builder: (context, reportSnap) {
                              if (reportSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final reports = reportSnap.data ?? [];
                              if (reports.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No progress reports yet. Add your first report to keep your client updated!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children:
                                    reports
                                        .map(
                                          (report) => Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: ListTile(
                                              leading: const CircleAvatar(
                                                backgroundColor: Colors.orange,
                                                child: Icon(
                                                  Icons.description,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              title: Text(
                                                report['content'] ?? '',
                                              ),
                                              subtitle: Text(
                                                'Posted: ${DateTime.parse(report['created_at']).toLocal().toString().split('.')[0]}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                size: 24,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Progress Photos',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Add Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _photosFuture,
                            builder: (context, photoSnap) {
                              if (photoSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final photos = photoSnap.data ?? [];
                              if (photos.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No photos uploaded yet. Add photos to show your progress!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.2,
                                    ),
                                itemCount: photos.length,
                                itemBuilder: (context, index) {
                                  final photo = photos[index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photo['photo_url'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                size: 24,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cost Breakdown',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: _addCost,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Cost'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _costsFuture,
                            builder: (context, costSnap) {
                              if (costSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final costs = costSnap.data ?? [];
                              if (costs.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No cost items added yet. Add costs to track project expenses!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final totalCost = costs.fold<double>(
                                0,
                                (sum, c) =>
                                    sum + (c['amount'] as num? ?? 0).toDouble(),
                              );
                              return Column(
                                children: [
                                  ...costs.map(
                                    (cost) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.green,
                                          child: Icon(
                                            Icons.receipt,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(cost['item'] ?? ''),
                                        subtitle:
                                            cost['note'] != null
                                                ? Text(cost['note'] ?? '')
                                                : null,
                                        trailing: Text(
                                          '₱${(cost['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(thickness: 2),
                                  Card(
                                    color: Colors.green[50],
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(
                                          Icons.calculate,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: const Text(
                                        'Total Project Cost',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: Text(
                                        '₱${totalCost.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All updates are shared in real-time with your client. Keep them informed with regular progress reports and photos.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

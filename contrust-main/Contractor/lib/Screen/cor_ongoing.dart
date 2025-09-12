// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Screen/cor_product.dart';

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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600,
            height: 500,
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Progress Report',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TextField(
                    controller: reportController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Enter progress report...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
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
                                  content: Text('Report added successfully!'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Add Report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final userId = _supabase.auth.currentUser?.id;

        if (userId != null) {
          final fileName =
              '${widget.projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storagePath = '$userId/$fileName';

          await _supabase.storage
              .from('projectphotos')
              .uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );

          await _projectService.addPhotoToProject(
            projectId: widget.projectId,
            photoUrl: storagePath,
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

  Future<String?> _createSignedPhotoUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) {
      return path;
    }
    try {
      final url = await _supabase.storage
          .from('projectphotos')
          .createSignedUrl(path, 60 * 60);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteTask(taskId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
        }
      }
    }
  }

  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Report'),
            content: const Text('Are you sure you want to delete this report?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteReport(reportId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting report: $e')));
        }
      }
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Photo'),
            content: const Text('Are you sure you want to delete this photo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deletePhoto(photoId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting photo: $e')));
        }
      }
    }
  }

  Future<void> _deleteCost(String materialId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Material'),
            content: const Text(
              'Are you sure you want to delete this material?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteCost(materialId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting material: $e')),
          );
        }
      }
    }
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
          final clientName = project['full_name'] ?? 'Client';
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
                              : () {
                                final screenWidth =
                                    MediaQuery.of(context).size.width;
                                final isDesktop = screenWidth > 1200;

                                if (isDesktop) {
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isDesktop ? 3 : 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 5,
                                          childAspectRatio: isDesktop ? 6 : 4,
                                        ),
                                    itemCount: _localTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = _localTasks[index];
                                      return _buildTaskItem(task);
                                    },
                                  );
                                } else {
                                  return Column(
                                    children:
                                        _localTasks
                                            .map((task) => _buildTaskItem(task))
                                            .toList(),
                                  );
                                }
                              }(),
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

                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isDesktop = screenWidth > 1200;

                              if (isDesktop) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isDesktop ? 3 : 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: isDesktop ? 6.5 : 4,
                                      ),
                                  itemCount: reports.length,
                                  itemBuilder: (context, index) {
                                    final report = reports[index];
                                    return _buildReportItem(report);
                                  },
                                );
                              } else {
                                return Column(
                                  children:
                                      reports
                                          .map(
                                            (report) =>
                                                _buildReportItem(report),
                                          )
                                          .toList(),
                                );
                              }
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

                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isDesktop = screenWidth > 1200;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isDesktop ? 3 : 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: isDesktop ? 2 : 3,
                                    ),
                                itemCount: photos.length,
                                itemBuilder: (context, index) {
                                  final photo = photos[index];
                                  final path = photo['photo_url'] as String?;
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder<String?>(
                                          future: _createSignedPhotoUrl(path),
                                          builder: (context, snap) {
                                            if (!snap.hasData) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            }
                                            final url = snap.data;
                                            if (url == null) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              );
                                            }
                                            return SizedBox.expand(
                                              child: Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                alignment: Alignment.center,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.error,
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            onPressed:
                                                () => _deletePhoto(
                                                  photo['photo_id'],
                                                ),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProductPanelScreen(
                                            projectId: widget.projectId,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.inventory),
                                label: const Text('Manage Materials'),
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
                              final validCosts =
                                  costs.where((c) {
                                    final unitPrice =
                                        (c['unit_price'] as num? ?? 0)
                                            .toDouble();
                                    return unitPrice > 0;
                                  }).toList();

                              if (validCosts.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No materials with costs added yet. Add materials to track project costs!',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final totalCost = validCosts.fold<double>(0, (
                                sum,
                                c,
                              ) {
                                final quantity =
                                    (c['quantity'] as num? ?? 0).toDouble();
                                final unitPrice =
                                    (c['unit_price'] as num? ?? 0).toDouble();
                                return sum + (quantity * unitPrice);
                              });

                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isDesktop = screenWidth > 1200;

                              return Column(
                                children: [
                                  if (isDesktop)
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: isDesktop ? 3 : 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: isDesktop ? 5 : 4,
                                          ),
                                      itemCount: validCosts.length,
                                      itemBuilder: (context, index) {
                                        final cost = validCosts[index];
                                        return _buildCostItem(cost);
                                      },
                                    )
                                  else
                                    ...validCosts.map(
                                      (cost) => _buildCostItem(cost),
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

  Widget _buildReportItem(Map<String, dynamic> report) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.description, color: Colors.white),
        ),
        title: Text(
          report['content'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Posted: ${DateTime.parse(report['created_at']).toLocal().toString().split('.')[0]}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteReport(report['report_id']),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(
          task['task'] ?? '',
          style: TextStyle(
            decoration:
                task['done'] == true ? TextDecoration.lineThrough : null,
            color: task['done'] == true ? Colors.grey[600] : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: task['done'] == true,
        onChanged: (val) {
          final taskId = task['task_id'];
          _updateTaskStatus(taskId.toString(), val ?? false);
        },
        activeColor: Colors.green,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteTask(task['task_id']),
        ),
      ),
    );
  }

  Widget _buildCostItem(Map<String, dynamic> cost) {
    final quantity = (cost['quantity'] as num? ?? 0).toDouble();
    final unitPrice = (cost['unit_price'] as num? ?? 0).toDouble();
    final totalItemCost = quantity * unitPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.construction, color: Colors.white),
        ),
        title: Text(cost['material_name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cost['brand'] != null) Text('Brand: ${cost['brand']}'),
            Text(
              'Qty: ${quantity.toStringAsFixed(1)} ${cost['unit'] ?? 'pcs'}',
            ),
            Text('Unit Price: ₱${unitPrice.toStringAsFixed(2)}'),
            if (cost['notes'] != null)
              Text(
                'Note: ${cost['notes']}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${totalItemCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteCost(cost['material_id']),
            ),
          ],
        ),
      ),
    );
  }
}

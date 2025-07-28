import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_project_service.dart';
import 'package:contractee/pages/cee_messages.dart';
import 'package:flutter/material.dart';

class CeeOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CeeOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CeeOngoingProjectScreen> createState() => _CeeOngoingProjectScreenState();
}

class _CeeOngoingProjectScreenState extends State<CeeOngoingProjectScreen> {
  late Future<Map<String, dynamic>?> _projectFuture;
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  late Future<List<String>> _photosFuture;
  late Future<List<Map<String, dynamic>>> _costsFuture;
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _projectFuture = ProjectService().getProjectDetails(widget.projectId);
    _reportsFuture = Future.value([]);
    _photosFuture = Future.value([]);
    _costsFuture = Future.value([]);
    _tasksFuture = Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const ConTrustAppBar(headline: 'Ongoing Project'),
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
          final contractorName = project['contractor_name'] ?? 'Contractor';
          final contractorPhoto = project['contractor_photo'] ?? '';
          final address = project['location'] ?? '';
          final startDate = project['start_date'] ?? '';
          final estimatedCompletion = project['estimated_completion'] ?? '';
          final progress = (project['progress'] as num?)?.toDouble() ?? 0.0;
          final contracteeId = project['contractee_id'] ?? '';
          final contractorId = project['contractor_id'] ?? '';
          final chatRoomId = project['chatroom_id'] ?? '';
          final contractorProfile = contractorPhoto;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: contractorPhoto.isNotEmpty ? NetworkImage(contractorPhoto) : null,
                      child: contractorPhoto.isEmpty ? const Icon(Icons.business, size: 32) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(projectTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Contractor: $contractorName', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Chat with Contractor',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagePageContractee(
                              chatRoomId: chatRoomId,
                              contracteeId: contracteeId,
                              contractorId: contractorId,
                              contractorName: contractorName,
                              contractorProfile: contractorProfile,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Project Info
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(address)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text('Start: $startDate'),
                            const SizedBox(width: 16),
                            const Icon(Icons.flag, size: 20),
                            const SizedBox(width: 8),
                            Text('Est. Completion: $estimatedCompletion'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Status: ${(progress * 100).toStringAsFixed(0)}% complete', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: progress, minHeight: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Tasks
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.checklist, size: 20),
                            const SizedBox(width: 8),
                            Text('Tasks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _tasksFuture,
                          builder: (context, taskSnap) {
                            if (taskSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final tasks = taskSnap.data ?? [];
                            if (tasks.isEmpty) {
                              return const Text('No tasks yet.');
                            }
                            return Column(
                              children: tasks.map((task) => ListTile(
                                leading: Icon(task['done'] == true ? Icons.check_circle : Icons.radio_button_unchecked, color: task['done'] == true ? Colors.green : Colors.grey),
                                title: Text(task['task'] ?? ''),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Reports
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.article, size: 20),
                            const SizedBox(width: 8),
                            Text('Progress Reports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _reportsFuture,
                          builder: (context, reportSnap) {
                            if (reportSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final reports = reportSnap.data ?? [];
                            if (reports.isEmpty) {
                              return const Text('No reports yet.');
                            }
                            return Column(
                              children: reports.map((r) => ListTile(
                                leading: const Icon(Icons.description_outlined),
                                title: Text(r['content'] ?? ''),
                                subtitle: Text(r['date'] ?? ''),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Photos
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_library, size: 20),
                            const SizedBox(width: 8),
                            Text('Photos of Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<String>>(
                          future: _photosFuture,
                          builder: (context, photoSnap) {
                            if (photoSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final photos = photoSnap.data ?? [];
                            if (photos.isEmpty) {
                              return const Text('No photos yet.');
                            }
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(photos[index], fit: BoxFit.cover),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Cost Breakdown
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 20),
                            const SizedBox(width: 8),
                            Text('Cost Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _costsFuture,
                          builder: (context, costSnap) {
                            if (costSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final costs = costSnap.data ?? [];
                            if (costs.isEmpty) {
                              return const Text('No cost breakdown yet.');
                            }
                            final totalCost = costs.fold<double>(0, (sum, c) => sum + (c['amount'] as num? ?? 0).toDouble());
                            return Column(
                              children: [
                                ...costs.map((c) => ListTile(
                                  title: Text(c['item'] ?? ''),
                                  trailing: Text('₱${c['amount'] ?? ''}'),
                                )),
                                const Divider(),
                                ListTile(
                                  title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: Text('₱${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                // Info
                Center(
                  child: Text(
                    'This page updates in real time as your contractor adds progress.\nFor questions, use the chat button above.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

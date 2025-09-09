// ignore_for_file: use_build_context_synchronously

import 'package:backend/models/be_appbar.dart';
import 'package:backend/services/be_fetchservice.dart';
import 'package:backend/utils/be_constraint.dart';
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
  late Future<Map<String, dynamic>?> _projectFuture;
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  late Future<List<Map<String, dynamic>>> _photosFuture;
  late Future<List<Map<String, dynamic>>> _costsFuture;
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  final _fetchService = FetchService();
  final supabase = Supabase.instance.client;
  String? _chatRoomId;
  bool _canChat = false;
  Map<String, dynamic>? _contractorData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getChatRoomId();
    _checkChatPermission();
    _loadContractorData();
  }

  Future<void> _getChatRoomId() async {
    try {
      final chatRoomId = await _fetchService.fetchChatRoomId(widget.projectId);
      setState(() {
        _chatRoomId = chatRoomId;
      });
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error getting chatroom_id')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error checking chat permission')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading contractor data')),
      );
    }
  }

  void _loadData() {
    setState(() {
      _projectFuture = _fetchService.fetchProjectDetails(widget.projectId);
      _reportsFuture = _fetchService.fetchProjectReports(widget.projectId);
      _photosFuture = _fetchService.fetchProjectPhotos(widget.projectId);
      _costsFuture = _fetchService.fetchProjectCosts(widget.projectId);
      _tasksFuture = _fetchService.fetchProjectTasks(widget.projectId);
    });
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
           final address = project['location'] ?? '';
           final startDate = project['start_date'] ?? '';
           final estimatedCompletion = project['estimated_completion'] ?? '';
           final progress = (project['progress'] as num?)?.toDouble() ?? 0.0;
           final contracteeId = project['contractee_id'] ?? '';
           final contractorId = project['contractor_id'] ?? '';
           
           final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
           final contractorPhoto = _contractorData?['profile_photo'] ?? '';

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: contractorPhoto.isNotEmpty ? NetworkImage(contractorPhoto) : null,
                            child: contractorPhoto.isEmpty ? const Icon(Icons.business, size: 32) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  projectTitle,
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Contractor: $contractorName',
                                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                            IconButton(
                             icon: const Icon(Icons.chat_bubble_outline, size: 28),
                             tooltip: 'Chat with Contractor',
                             onPressed: _canChat && _chatRoomId != null
                                 ? () {
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
                                 : null,
                           ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Colors.orange, Colors.deepOrange],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.article, size: 22, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Progress Reports',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.location_on, size: 20, color: Colors.red),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  address,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Start: $startDate',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.flag, size: 20, color: Colors.green),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Est. Completion: $estimatedCompletion',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                             FutureBuilder<List<Map<String, dynamic>>>(
                             future: _tasksFuture,
                             builder: (context, taskSnap) {
                               final tasks = taskSnap.data ?? [];
                               final completedTasks = tasks.where((task) => task['done'] == true).length;
                               final totalTasks = tasks.length;
                               
                               return Row(
                                 children: [
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Row(
                                           children: [
                                             Text(
                                               'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                             ),
                                             const SizedBox(width: 16),
                                             Text(
                                               'Tasks: $completedTasks/$totalTasks completed',
                                               style: TextStyle(
                                                 fontWeight: FontWeight.w500,
                                                 color: Colors.grey[600],
                                                 fontSize: 14,
                                               ),
                                             ),
                                           ],
                                         ),
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 12,
                                              backgroundColor: Colors.grey[300],
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                progress >= 1.0 ? Colors.green : Colors.blue,
                                           ),
                                         ),
                                        )
                                       ],
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
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.checklist, size: 26, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Project Tasks',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _tasksFuture,
                            builder: (context, taskSnap) {
                              if (taskSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final tasks = taskSnap.data ?? [];
                              if (tasks.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'No tasks have been added by your contractor yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: tasks.map((task) {
                                  final isDone = task['done'] == true;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: isDone ? Colors.green : Colors.grey[400],
                                        child: Icon(
                                          isDone ? Icons.check_rounded : Icons.radio_button_unchecked,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        task['task'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                          color: isDone ? Colors.grey[600] : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.article, size: 24, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Progress Reports',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _reportsFuture,
                            builder: (context, reportSnap) {
                              if (reportSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final reports = reportSnap.data ?? [];
                              if (reports.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No progress reports have been shared by your contractor yet.',
                                      style: TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: reports.map((report) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      child: Icon(Icons.description, color: Colors.white),
                                    ),
                                    title: Text(report['content'] ?? ''),
                                    subtitle: Text(
                                      'Posted: ${DateTime.parse(report['created_at']).toLocal().toString().split('.')[0]}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                )).toList(),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_library, size: 24, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                'Progress Photos',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _photosFuture,
                            builder: (context, photoSnap) {
                              if (photoSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final photos = photoSnap.data ?? [];
                              if (photos.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No progress photos have been shared by your contractor yet.',
                                      style: TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: photos.length,
                                itemBuilder: (context, index) {
                                  final photo = photos[index];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photo['photo_url'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_money, size: 24, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Cost Breakdown',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _costsFuture,
                            builder: (context, costSnap) {
                              if (costSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final costs = costSnap.data ?? [];
                              if (costs.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No cost breakdown has been provided by your contractor yet.',
                                      style: TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                );
                              }
                              final totalCost = costs.fold<double>(
                                0, 
                                (sum, c) => sum + (c['amount'] as num? ?? 0).toDouble()
                              );
                              return Column(
                                children: [
                                  ...costs.map((cost) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.receipt, color: Colors.white),
                                      ),
                                      title: Text(cost['item'] ?? ''),
                                      subtitle: cost['note'] != null 
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
                                  )),
                                  const Divider(thickness: 2),
                                  Card(
                                    color: Colors.green[50],
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.calculate, color: Colors.white),
                                      ),
                                      title: const Text(
                                        'Total Project Cost',
                                        style: TextStyle(fontWeight: FontWeight.bold),
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
                              'This page updates in real-time as your contractor adds progress. For questions or concerns, use the chat button above.',
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

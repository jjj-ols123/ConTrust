// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class OngoingBuildMethods {
  static Widget buildProjectHeader({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    required String estimatedCompletion,
    required double progress,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.construction, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Client: $clientName',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Started: $startDate',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Est. Completion: $estimatedCompletion',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Project Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    VoidCallback? onAdd,
    String? addButtonText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (onAdd != null)
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(addButtonText ?? 'Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  static Widget buildTasksList({
    required List<Map<String, dynamic>> tasks,
    required Function(String, bool) onUpdateTaskStatus,
    required Function(String) onDeleteTask,
  }) {
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No tasks added yet'),
        ),
      );
    }
    return Column(
      children:
          tasks
              .map(
                (task) => buildTaskItem(
                  task: task,
                  onUpdateStatus: onUpdateTaskStatus,
                  onDelete: onDeleteTask,
                ),
              )
              .toList(),
    );
  }

  static Widget buildReportsList({
    required List<Map<String, dynamic>> reports,
    required Function(String) onDeleteReport,
  }) {
    if (reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No reports added yet'),
        ),
      );
    }
    return Column(
      children:
          reports
              .map(
                (report) =>
                    buildReportItem(report: report, onDelete: onDeleteReport),
              )
              .toList(),
    );
  }

  static Widget buildPhotosList({
    required List<Map<String, dynamic>> photos,
    required Future<String?> Function(String?) createSignedUrl,
    required Function(String) onDeletePhoto,
  }) {
    if (photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No photos added yet'),
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
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return FutureBuilder<String?>(
          future: createSignedUrl(photo['photo_url']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image:
                        snapshot.hasData && snapshot.data != null
                            ? DecorationImage(
                              image: NetworkImage(snapshot.data!),
                              fit: BoxFit.cover,
                            )
                            : null,
                    color: Colors.grey[200],
                  ),
                  child:
                      snapshot.hasData && snapshot.data != null
                          ? null
                          : const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onDeletePhoto(photo['photo_id']),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget buildCostsList({
    required List<Map<String, dynamic>> costs,
    required Function(String) onDeleteCost,
  }) {
    if (costs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No materials added yet'),
        ),
      );
    }

    double totalCost = 0;
    for (var cost in costs) {
      final quantity = (cost['quantity'] as num? ?? 0).toDouble();
      final unitPrice = (cost['unit_price'] as num? ?? 0).toDouble();
      totalCost += quantity * unitPrice;
    }

    return Column(
      children: [
        ...costs.map(
          (cost) => buildCostItem(cost: cost, onDelete: onDeleteCost),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Cost:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₱${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildReportItem({
    required Map<String, dynamic> report,
    required Function(String) onDelete,
  }) {
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
          onPressed: () => onDelete(report['report_id']),
        ),
      ),
    );
  }

  static Widget buildTaskItem({
    required Map<String, dynamic> task,
    required Function(String, bool) onUpdateStatus,
    required Function(String) onDelete,
  }) {
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
          onUpdateStatus(taskId.toString(), val ?? false);
        },
        activeColor: Colors.green,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDelete(task['task_id']),
        ),
      ),
    );
  }

  static Widget buildCostItem({
    required Map<String, dynamic> cost,
    required Function(String) onDelete,
  }) {
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
              onPressed: () => onDelete(cost['material_id']),
            ),
          ],
        ),
      ),
    );
  }

  static void showAddReportDialog({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) {
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
            padding: const EdgeInsets.all(32),
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
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Enter progress details...',
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
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          onAdd();
                          Navigator.pop(context);
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

  static void showAddTaskDialog({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: TextField(
            controller: controller,
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
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  static Widget buildMobileTabNavigation(String selectedTab, Function(String) onTabChanged) {
    final tabs = ['Tasks', 'Reports', 'Photos', 'Materials'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = selectedTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isActive ? Colors.orange.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.orange.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

 
  static Widget buildMobileLayout({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    required String estimatedCompletion,
    required double progress,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget tabContent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          buildProjectHeader(
            projectTitle: projectTitle,
            clientName: clientName,
            address: address,
            startDate: startDate,
            estimatedCompletion: estimatedCompletion,
            progress: progress,
          ),
          const SizedBox(height: 16),
          buildMobileTabNavigation(selectedTab, onTabChanged),
          const SizedBox(height: 16),
          Expanded(child: tabContent),
        ],
      ),
    );
  }

  static Widget buildTabContent({
    required String selectedTab,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> photos,
    required List<Map<String, dynamic>> costs,
    required Function(String, bool) onUpdateTaskStatus,
    required Function(String) onDeleteTask,
    required Function(String) onDeleteReport,
    required Function(String) onDeletePhoto,
    required Function(String) onDeleteCost,
    required Future<String?> Function(String?) createSignedUrl,
    required VoidCallback onAddTask,
    required VoidCallback onAddReport,
    required VoidCallback onAddPhoto,
  }) {
    switch (selectedTab) {
      case 'Tasks':
        return buildSectionCard(
          title: 'Tasks & Progress',
          icon: Icons.checklist,
          iconColor: Colors.blue,
          onAdd: onAddTask,
          addButtonText: 'Add Task',
          child: buildTasksList(
            tasks: tasks,
            onUpdateTaskStatus: onUpdateTaskStatus,
            onDeleteTask: onDeleteTask,
          ),
        );
      case 'Reports':
        return buildSectionCard(
          title: 'Progress Reports',
          icon: Icons.description,
          iconColor: Colors.orange,
          onAdd: onAddReport,
          addButtonText: 'Add Report',
          child: buildReportsList(
            reports: reports,
            onDeleteReport: onDeleteReport,
          ),
        );
      case 'Photos':
        return buildSectionCard(
          title: 'Project Photos',
          icon: Icons.photo_library,
          iconColor: Colors.green,
          onAdd: onAddPhoto,
          addButtonText: 'Add Photo',
          child: buildPhotosList(
            photos: photos,
            createSignedUrl: createSignedUrl,
            onDeletePhoto: onDeletePhoto,
          ),
        );
      case 'Materials':
        return buildSectionCard(
          title: 'Materials & Costs',
          icon: Icons.construction,
          iconColor: Colors.purple,
          child: buildCostsList(
            costs: costs,
            onDeleteCost: onDeleteCost,
          ),
        );
      default:
        return buildSectionCard(
          title: 'Tasks & Progress',
          icon: Icons.checklist,
          iconColor: Colors.blue,
          onAdd: onAddTask,
          addButtonText: 'Add Task',
          child: buildTasksList(
            tasks: tasks,
            onUpdateTaskStatus: onUpdateTaskStatus,
            onDeleteTask: onDeleteTask,
          ),
        );
    }
  }

  static Widget buildDesktopGridLayout({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    required String estimatedCompletion,
    required double progress,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> photos,
    required List<Map<String, dynamic>> costs,
    required Function(String, bool) onUpdateTaskStatus,
    required Function(String) onDeleteTask,
    required Function(String) onDeleteReport,
    required Function(String) onDeletePhoto,
    required Function(String) onDeleteCost,
    required Future<String?> Function(String?) createSignedUrl,
    required VoidCallback onAddTask,
    required VoidCallback onAddReport,
    required VoidCallback onAddPhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          buildProjectHeader(
            projectTitle: projectTitle,
            clientName: clientName,
            address: address,
            startDate: startDate,
            estimatedCompletion: estimatedCompletion,
            progress: progress,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: buildGridSectionCard(
                          title: 'Tasks & Progress',
                          icon: Icons.checklist,
                          iconColor: Colors.blue,
                          onAdd: onAddTask,
                          addButtonText: 'Add Task',
                          child: buildDesktopTasksList(
                            tasks: tasks,
                            onUpdateTaskStatus: onUpdateTaskStatus,
                            onDeleteTask: onDeleteTask,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildGridSectionCard(
                          title: 'Project Photos',
                          icon: Icons.photo_library,
                          iconColor: Colors.green,
                          onAdd: onAddPhoto,
                          addButtonText: 'Add Photo',
                          child: buildDesktopPhotosList(
                            photos: photos,
                            createSignedUrl: createSignedUrl,
                            onDeletePhoto: onDeletePhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: buildGridSectionCard(
                          title: 'Progress Reports',
                          icon: Icons.description,
                          iconColor: Colors.orange,
                          onAdd: onAddReport,
                          addButtonText: 'Add Report',
                          child: buildDesktopReportsList(
                            reports: reports,
                            onDeleteReport: onDeleteReport,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildGridSectionCard(
                          title: 'Materials & Costs',
                          icon: Icons.construction,
                          iconColor: Colors.purple,
                          child: buildDesktopCostsList(
                            costs: costs,
                            onDeleteCost: onDeleteCost,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildGridSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    VoidCallback? onAdd,
    String? addButtonText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (onAdd != null)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(addButtonText ?? 'Add', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDesktopTasksList({
    required List<Map<String, dynamic>> tasks,
    required Function(String, bool) onUpdateTaskStatus,
    required Function(String) onDeleteTask,
  }) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks yet', style: TextStyle(color: Colors.grey)),
      );
    }
    
    return ListView.builder(
      itemCount: tasks.take(10).length, 
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Checkbox(
                value: task['done'] == true,
                onChanged: (val) => onUpdateTaskStatus(task['task_id'].toString(), val ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Text(
                  task['task'] ?? '',
                  style: TextStyle(
                    decoration: task['done'] == true ? TextDecoration.lineThrough : null,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => onDeleteTask(task['task_id']),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildDesktopReportsList({
    required List<Map<String, dynamic>> reports,
    required Function(String) onDeleteReport,
  }) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('No reports yet', style: TextStyle(color: Colors.grey)),
      );
    }
    
    return ListView.builder(
      itemCount: reports.take(8).length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  report['content'] ?? '',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => onDeleteReport(report['report_id']),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget buildDesktopPhotosList({
    required List<Map<String, dynamic>> photos,
    required Future<String?> Function(String?) createSignedUrl,
    required Function(String) onDeletePhoto,
  }) {
    if (photos.isEmpty) {
      return const Center(
        child: Text('No photos yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.take(12).length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return FutureBuilder<String?>(
          future: createSignedUrl(photo['photo_url']),
          builder: (context, snapshot) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: snapshot.hasData && snapshot.data != null
                        ? DecorationImage(
                            image: NetworkImage(snapshot.data!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: snapshot.hasData && snapshot.data != null
                      ? null
                      : const Center(child: Icon(Icons.image, size: 16)),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onDeletePhoto(photo['photo_id']),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget buildDesktopCostsList({
    required List<Map<String, dynamic>> costs,
    required Function(String) onDeleteCost,
  }) {
    if (costs.isEmpty) {
      return const Center(
        child: Text('No materials yet', style: TextStyle(color: Colors.grey)),
      );
    }

    double totalCost = 0;
    for (var cost in costs) {
      final quantity = (cost['quantity'] as num? ?? 0).toDouble();
      final unitPrice = (cost['unit_price'] as num? ?? 0).toDouble();
      totalCost += quantity * unitPrice;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '₱${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: costs.take(10).length,
            itemBuilder: (context, index) {
              final cost = costs[index];
              final quantity = (cost['quantity'] as num? ?? 0).toDouble();
              final unitPrice = (cost['unit_price'] as num? ?? 0).toDouble();
              final itemTotal = quantity * unitPrice;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cost['material_name'] ?? '',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${quantity.toStringAsFixed(1)} × ₱${unitPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₱${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 14),
                      onPressed: () => onDeleteCost(cost['material_id']),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
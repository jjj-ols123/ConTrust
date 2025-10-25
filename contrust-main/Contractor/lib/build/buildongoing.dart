// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backend/utils/be_contractformat.dart'; 

class OngoingBuildMethods {
  static Widget buildProjectHeader({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    String? estimatedCompletion,
    required int? duration,
    required bool isCustomContract,
    required double progress,
    VoidCallback? onRefresh,
    VoidCallback? onEditCompletion,
    VoidCallback? onSwitchProject,
  }) {

    DateTime? completionDate;
    final raw = estimatedCompletion?.trim().toLowerCase();
    if (raw != null && raw.isNotEmpty && raw != 'placeholder' && raw != 'tbd' && raw != 'n/a') {
      try {
        completionDate = DateTime.parse(estimatedCompletion!);
      } catch (_) {
        try {
          final parts = estimatedCompletion!.split(' ');
          completionDate = DateTime.parse(parts.first);
        } catch (_) {
          completionDate = null;
        }
      }
    }

    if (completionDate == null && startDate.isNotEmpty && duration != null) {
      try {
        final start = DateTime.parse(startDate);
        completionDate = start.add(Duration(days: duration));
      } catch (_) {
        completionDate = null;
      }
    }

    String countdownText = 'Duration: Not set';
    if (completionDate != null) {
      final now = DateTime.now();
      final daysLeft = completionDate.difference(now).inDays;
      if (daysLeft > 0) {
        countdownText = 'Duration: $daysLeft days left';
      } else if (daysLeft == 0) {
        countdownText = 'Duration: Due today';
      } else {
        countdownText = 'Duration: Overdue by ${daysLeft.abs()} days';
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                
                if (isMobile) {
                  return Column(
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Client: $clientName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCustomContract && onEditCompletion != null)
                            IconButton(
                              onPressed: onEditCompletion,
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              tooltip: 'Edit Completion Date',
                            ),
                          if (onSwitchProject != null)
                            IconButton(
                              onPressed: onSwitchProject,
                              icon: const Icon(Icons.swap_horiz, color: Colors.orange, size: 20),
                              tooltip: 'Switch Project',
                            ),
                          if (onRefresh != null)
                            IconButton(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                              tooltip: 'Refresh',
                            ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
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
                if (isCustomContract && onEditCompletion != null)
                  IconButton(
                    onPressed: onEditCompletion,
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit Completion Date',
                  ),
                if (onSwitchProject != null)
                  IconButton(
                    onPressed: onSwitchProject,
                    icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                    tooltip: 'Switch Project',
                  ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    tooltip: 'Refresh',
                  ),
              ],
                  );
                }
              },
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
                  'Started: ${ContractStyle.formatDate(startDate)}', 
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
                  'Est. Completion: ${ContractStyle.formatDate(estimatedCompletion)}', 
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  countdownText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
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

  static void showEditCompletionDialog({
    required BuildContext context,
    required DateTime? currentCompletion,
    required Function(DateTime) onSave,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentCompletion ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (selectedDate != null) {
      onSave(selectedDate);
    }
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
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
                    Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isMobile = screenWidth < 600;
                        if (isMobile) {
                          return IconButton(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            tooltip: addButtonText ?? 'Add',
                          );
                        } else {
                          return ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(addButtonText ?? 'Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                          );
                        }
                      },
                    ),
                ],
              ),
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
    Function(Map<String, dynamic>)? onViewReport,
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
                (report) => buildReportItem(
                  report: report,
                  onDelete: onDeleteReport,
                  onTap:
                      onViewReport != null ? () => onViewReport(report) : null,
                ),
              )
              .toList(),
    );
  }

  static Widget buildPhotosList({
    required List<Map<String, dynamic>> photos,
    required Future<String?> Function(String?) createSignedUrl,
    required Function(String) onDeletePhoto,
    Function(Map<String, dynamic>)? onViewPhoto,
  }) {
    if (photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No photos added yet'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 6 : 8,
            mainAxisSpacing: isMobile ? 6 : 8,
            childAspectRatio: isMobile ? 1.0 : 1.0,
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
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: isMobile ? 20 : 24,
                        height: isMobile ? 20 : 24,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              );
            }

            return Stack(
              children: [
                GestureDetector(
                  onTap: onViewPhoto != null ? () => onViewPhoto(photo) : null,
                  child: Container(
                    decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
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
                            : Center(
                              child: Icon(
                                Icons.image, 
                                color: Colors.grey,
                                size: isMobile ? 24 : 32,
                              ),
                            ),
                  ),
                ),
                Positioned(
                      top: isMobile ? 2 : 4,
                      right: isMobile ? 2 : 4,
                  child: GestureDetector(
                    onTap: () => onDeletePhoto(photo['photo_id']),
                    child: Container(
                          padding: EdgeInsets.all(isMobile ? 3 : 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                          child: Icon(
                        Icons.delete,
                        color: Colors.white,
                            size: isMobile ? 12 : 16,
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
      },
    );
  }

  static Widget buildCostsList({
    required List<Map<String, dynamic>> costs,
    required Function(String) onDeleteCost,
    Function(Map<String, dynamic>)? onViewMaterial,
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
          (cost) => buildCostItem(
            cost: cost,
            onDelete: onDeleteCost,
            onTap: onViewMaterial != null ? () => onViewMaterial(cost) : null,
          ),
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
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 20,
                          child: Icon(Icons.description, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            report['content'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onDelete(report['report_id']),
                          color: Colors.red[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posted: ${DateTime.parse(report['created_at']).toLocal().toString().split('.')[0]}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return ListTile(
        onTap: onTap,
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
            );
          }
        },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: task['done'] == true,
                    onChanged: (val) {
                      final taskId = task['task_id'];
                      onUpdateStatus(taskId.toString(), val ?? false);
                    },
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['task'] ?? '',
                          style: TextStyle(
                            decoration: task['done'] == true ? TextDecoration.lineThrough : null,
                            color: task['done'] == true ? Colors.grey[600] : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task['created_at'] != null
                              ? 'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}'
                              : 'Created: Unknown',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => onDelete(task['task_id']),
                    color: Colors.red[600],
                  ),
                ],
              ),
            );
          } else {
            return CheckboxListTile(
        title: Text(
          task['task'] ?? '',
          style: TextStyle(
                  decoration: task['done'] == true ? TextDecoration.lineThrough : null,
            color: task['done'] == true ? Colors.grey[600] : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          task['created_at'] != null
              ? 'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}'
              : 'Created: Unknown',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: task['done'] == true,
        onChanged: (val) {
          final taskId = task['task_id'];
          onUpdateStatus(taskId.toString(), val ?? false);
        },
        activeColor: Colors.green,
        checkColor: Colors.amber[700],
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDelete(task['task_id']),
        ),
            );
          }
        },
      ),
    );
  }

  static Widget buildCostItem({
    required Map<String, dynamic> cost,
    required Function(String) onDelete,
    VoidCallback? onTap,
  }) {
    final quantity = (cost['quantity'] as num? ?? 0).toDouble();
    final unitPrice = (cost['unit_price'] as num? ?? 0).toDouble();
    final totalItemCost = quantity * unitPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 20,
                          child: Icon(Icons.construction, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cost['material_name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '₱${totalItemCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (cost['brand'] != null) 
                      Text('Brand: ${cost['brand']}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Text(
                      'Qty: ${quantity.toStringAsFixed(1)} ${cost['unit'] ?? 'pcs'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'Unit Price: ₱${unitPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (cost['notes'] != null)
                      Text(
                        'Note: ${cost['notes']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onDelete(cost['material_id']),
                          color: Colors.red[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            return ListTile(
              onTap: onTap,
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
                    color: Colors.red[600],
                  ),
          ],
        ),
            );
          }
        },
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
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            width: 600,
            height: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Progress Report',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share updates and progress details for this project',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Enter progress details...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          onAdd();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
    required Function(List<String>) onAdd,
  }) {
    final List<TextEditingController> controllers = [TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.checklist,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add Multiple Tasks',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add one or more tasks for this project',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...controllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: 'Enter task ...',
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                        maxLines: null,
                                        minLines: 1,
                                      ),
                                    ),
                                    if (controllers.length > 1)
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red.shade400,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            controllers.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  controllers.add(TextEditingController());
                                });
                              },
                              icon: Icon(
                                Icons.add,
                                color: Colors.blue.shade700,
                              ),
                              label: Text(
                                'Add Another Task',
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue.shade700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final validTasks =
                                controllers
                                    .map((c) => c.text.trim())
                                    .where((text) => text.isNotEmpty)
                                    .toList();
                            if (validTasks.isNotEmpty) {
                              Navigator.pop(context);
                              onAdd(validTasks);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Add Tasks'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  static Widget buildMobileTabNavigation(
    String selectedTab,
    Function(String) onTabChanged,
  ) {
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
        children:
            tabs.map((tab) {
              final isActive = selectedTab == tab;
              return Expanded(
                child: InkWell(
                  onTap: () => onTabChanged(tab),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color:
                          isActive ? Colors.orange.shade50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tab,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isActive
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
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
    required int? duration, 
    required bool isCustomContract, 
    required double progress,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget tabContent,
    VoidCallback? onRefresh,
    VoidCallback? onEditCompletion, 
    VoidCallback? onSwitchProject,
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
            duration: duration,
            isCustomContract: isCustomContract, 
            progress: progress,
            onRefresh: onRefresh,
            onEditCompletion: onEditCompletion,
            onSwitchProject: onSwitchProject,
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
    required BuildContext context,
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
    VoidCallback? onGoToMaterials,
    Function(Map<String, dynamic>)? onViewReport,
    Function(Map<String, dynamic>)? onViewPhoto,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    Widget content;
    switch (selectedTab) {
      case 'Tasks':
        content = buildSectionCard(
          title: 'Tasks & Progress',
          icon: Icons.checklist,
          iconColor: Colors.black,
          onAdd: onAddTask,
          addButtonText: 'Add Task',
          child: buildTasksList(
            tasks: tasks,
            onUpdateTaskStatus: onUpdateTaskStatus,
            onDeleteTask: onDeleteTask,
          ),
        );
        break;
      case 'Reports':
        content = buildSectionCard(
          title: 'Progress Reports',
          icon: Icons.description,
          iconColor: Colors.black,
          onAdd: onAddReport,
          addButtonText: 'Add Report',
          child: buildReportsList(
            reports: reports,
            onDeleteReport: onDeleteReport,
            onViewReport: onViewReport,
          ),
        );
        break;
      case 'Photos':
        content = buildSectionCard(
          title: 'Project Photos',
          icon: Icons.photo_library,
          iconColor: Colors.black,
          onAdd: onAddPhoto,
          addButtonText: 'Add Photo',
          child: buildPhotosList(
            photos: photos,
            createSignedUrl: createSignedUrl,
            onDeletePhoto: onDeletePhoto,
            onViewPhoto: onViewPhoto,
          ),
        );
        break;
      case 'Materials':
        content = buildSectionCard(
          title: 'Materials & Costs',
          icon: Icons.construction,
          iconColor: Colors.black,
          onAdd: onGoToMaterials,
          addButtonText: 'Manage Materials',
          child: buildCostsList(
            costs: costs,
            onDeleteCost: onDeleteCost,
            onViewMaterial: (material) => showMaterialDetailsDialog(context, material),
          ),
        );
        break;
      default:
        content = buildSectionCard(
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
    
    if (isMobile) {
      return SingleChildScrollView(
        child: content,
      );
    } else {
      return content;
    }
  }

  static Widget buildDesktopGridLayout({
    required BuildContext context,
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    required String estimatedCompletion,
    required int? duration,
    required bool isCustomContract,
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
    VoidCallback? onGoToMaterials,
    Function(Map<String, dynamic>)? onViewReport,
    Function(Map<String, dynamic>)? onViewPhoto,
    VoidCallback? onRefresh,
    VoidCallback? onEditCompletion,
    VoidCallback? onSwitchProject,
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
            duration: duration, 
            isCustomContract: isCustomContract,
            progress: progress,
            onRefresh: onRefresh,
            onEditCompletion: onEditCompletion,
            onSwitchProject: onSwitchProject,
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
                          iconColor: Colors.grey,
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
                          iconColor: Colors.grey,
                          onAdd: onAddPhoto,
                          addButtonText: 'Add Photo',
                          child: buildDesktopPhotosList(
                            photos: photos,
                            createSignedUrl: createSignedUrl,
                            onDeletePhoto: onDeletePhoto,
                            onViewPhoto: onViewPhoto,
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
                          iconColor: Colors.grey,
                          onAdd: onAddReport,
                          addButtonText: 'Add Report',
                          child: buildDesktopReportsList(
                            reports: reports,
                            onDeleteReport: onDeleteReport,
                            onViewReport: onViewReport,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildGridSectionCard(
                          title: 'Materials & Costs',
                          icon: Icons.construction,
                          iconColor: Colors.grey,
                          onAdd: onGoToMaterials,
                          addButtonText: 'Manage Materials',
                          child: buildDesktopCostsList(
                            costs: costs,
                            onDeleteCost: onDeleteCost,
                            onViewMaterial:
                                (material) => showMaterialDetailsDialog(
                                  context,
                                  material,
                                ),
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
              color: Colors.grey.shade200,
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
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isMobile = screenWidth < 600;
                      if (isMobile) {
                        return IconButton(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                          ),
                          tooltip: addButtonText ?? 'Add',
                        );
                      } else {
                        return SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(
                        addButtonText ?? 'Add',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
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
                onChanged:
                    (val) => onUpdateTaskStatus(
                      task['task_id'].toString(),
                      val ?? false,
                    ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['task'] ?? '',
                      style: TextStyle(
                        decoration:
                            task['done'] == true
                                ? TextDecoration.lineThrough
                                : null,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      task['created_at'] != null
                          ? 'Created: ${DateTime.parse(task['created_at']).toLocal().toString().split('.')[0]}'
                          : 'Created: Unknown',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
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
    Function(Map<String, dynamic>)? onViewReport,
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
        return GestureDetector(
          onTap: onViewReport != null ? () => onViewReport(report) : null,
          child: Container(
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
          ),
        );
      },
    );
  }

  static Widget buildDesktopPhotosList({
    required List<Map<String, dynamic>> photos,
    required Future<String?> Function(String?) createSignedUrl,
    required Function(String) onDeletePhoto,
    Function(Map<String, dynamic>)? onViewPhoto,
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
                GestureDetector(
                  onTap: onViewPhoto != null ? () => onViewPhoto(photo) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
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
                            : const Center(child: Icon(Icons.image, size: 16)),
                  ),
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
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
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

  static Widget buildDesktopCostsList({
    required List<Map<String, dynamic>> costs,
    required Function(String) onDeleteCost,
    Function(Map<String, dynamic>)? onViewMaterial,
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
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '₱${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
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

              return InkWell(
                onTap:
                    onViewMaterial != null ? () => onViewMaterial(cost) : null,
                child: Container(
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${quantity.toStringAsFixed(1)} × ₱${unitPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${itemTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 14),
                        onPressed: () => onDeleteCost(cost['material_id']),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static void showReportDialog(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress Report',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${report['created_at'] != null ? DateTime.parse(report['created_at']).toLocal().toString().split(' ')[0] : 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          report['content'] ?? 'No content available',
                          style: const TextStyle(fontSize: 16),
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
    );
  }

  static void showPhotoDialog(
    BuildContext context,
    Map<String, dynamic> photo,
    Future<String?> Function(String?) createSignedUrl,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey[900],
          child: FutureBuilder<String?>(
            future: createSignedUrl(photo['photo_url']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              return Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    Center(
                      child:
                          snapshot.hasData && snapshot.data != null
                              ? InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 3.0,
                                child: Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                  width:
                                      MediaQuery.of(context).size.width * 0.95,
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                ),
                              )
                              : const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static void showMaterialDetailsDialog(
    BuildContext context,
    Map<String, dynamic> material,
  ) {
    final name =
        material['material_name'] ?? material['name'] ?? 'Unknown Material';
    final brand = material['brand'] ?? '';
    final qty = material['quantity'] ?? material['qty'] ?? 0;
    final unit = material['unit'] ?? 'pcs';
    final unitPrice = material['unit_price'] ?? material['unitPrice'] ?? 0;
    final total = material['total'] ?? ((qty as num) * (unitPrice as num));
    final notes = material['notes'] ?? material['note'] ?? '';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
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
                            Icons.construction,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Material Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Material Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (brand.isNotEmpty) ...[
                            Text(
                              'Brand',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              brand,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${qty.toString()} $unit',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unit Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${unitPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Total Cost',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${(total as num).toDouble().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (notes.isNotEmpty) ...[
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                notes,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

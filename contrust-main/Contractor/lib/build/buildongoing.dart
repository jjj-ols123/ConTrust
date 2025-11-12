// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:backend/utils/be_contractformat.dart'; 

class OngoingBuildMethods {
  /// Show date picker with amber theme matching add tasks dialog
  static Future<DateTime?> showThemedDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText ?? 'Select Date',
      cancelText: cancelText ?? 'Cancel',
      confirmText: confirmText ?? 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
  static Widget buildProjectHeader({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    String? estimatedCompletion,
    required int? duration,
    required bool isCustomContract,
    required double progress,
    String? contractStatusLabel,
    Color? contractStatusColor,
    VoidCallback? onViewContract,
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
        child: SingleChildScrollView(
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
                          if (contractStatusLabel != null && contractStatusLabel.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (contractStatusColor ?? Colors.grey).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: (contractStatusColor ?? Colors.grey).withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.assignment_turned_in,
                                      size: 14, color: contractStatusColor ?? Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    contractStatusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: contractStatusColor ?? Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.visibility,
                                      size: 14, color: contractStatusColor ?? Colors.grey),
                                ],
                              ),
                            ),
                          if (isCustomContract && onEditCompletion != null)
                            IconButton(
                              onPressed: onEditCompletion,
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              tooltip: 'Edit Completion Date',
                            ),
                          if (onViewContract != null)
                            ElevatedButton.icon(
                              onPressed: onViewContract,
                              icon: const Icon(Icons.description, size: 16),
                              label: const Text('View Contract', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          if (onSwitchProject != null)
                            IconButton(
                              onPressed: onSwitchProject,
                              icon: const Icon(Icons.swap_horiz, color: Colors.orange, size: 20),
                              tooltip: 'Switch Project',
                            ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
              children: [
                const Icon(Icons.construction, color: Colors.grey, size: 28),
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
                if (onViewContract != null)
                  ElevatedButton.icon(
                    onPressed: onViewContract,
                    icon: const Icon(Icons.description),
                    label: const Text('View Contract'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                if (isCustomContract && onEditCompletion != null)
                  IconButton(
                    onPressed: onEditCompletion,
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit Completion Date',
                  ),
                if (contractStatusLabel != null && contractStatusLabel.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (contractStatusColor ?? Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (contractStatusColor ?? Colors.grey).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment_turned_in, size: 16, color: contractStatusColor ?? Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          contractStatusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: contractStatusColor ?? Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.visibility, size: 16, color: contractStatusColor ?? Colors.grey),
                      ],
                    ),
                  ),
                if (onSwitchProject != null)
                  IconButton(
                    onPressed: onSwitchProject,
                    icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                    tooltip: 'Switch Project',
                  ),
              ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
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
                const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Started: ${ContractStyle.formatDate(startDate)}', 
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Est. Completion: ${ContractStyle.formatDate(estimatedCompletion)}', 
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.grey,
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
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.amber,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  static void showEditCompletionDialog({
    required BuildContext context,
    required DateTime? currentCompletion,
    required Function(DateTime) onSave,
  }) async {
    final now = DateTime.now();
    final initial = (currentCompletion != null && currentCompletion.isAfter(now))
        ? currentCompletion
        : now;
    final selectedDate = await showThemedDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
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
        final photoId = photo['photo_id']?.toString() ?? '';
        return FutureBuilder<String?>(
          key: ValueKey('photo_$photoId'),
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
                        child: const CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
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
                        const SizedBox(width: 12),
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
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDelete(report['report_id']),
          ),
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
                  const SizedBox(width: 12),
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
        secondary: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDelete(task['task_id']),
          ),
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

  static Future<void> showAddReportDialog({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
            child: Container(
                width: double.infinity,
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
                          Icons.description,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Add Progress Report',
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Share updates and progress details for this project',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                            Container(
                              constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                                minLines: 8,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                hintText: 'Enter progress details...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (controller.text.trim().isNotEmpty) {
                                      Navigator.of(dialogContext).pop();
                                  onAdd();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB300),
                                foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Add Report'),
                            ),
                          ],
                        ),
                      ],
                        ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          )
        );
      },
    );
  }

  static Future<void> showTestTaskDialog({
    required BuildContext context,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
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
                      color: Colors.blue.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Test Dialog',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Dialog is working!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If you can see this, the dialog system is functioning correctly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
      },
    );
  }

  static Future<void> showAddTaskDialog({
    required BuildContext context,
    required Function(List<Map<String, dynamic>>) onAdd,
  }) async {
    if (!context.mounted) return;
    
    final TextEditingController taskController = TextEditingController();
    final List<Map<String, dynamic>> addedTasks = [];

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                child: Container(
                    width: double.infinity,
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
                              Icons.checklist,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                                'Add Tasks',
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 500),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  'Enter task and select expected finish date',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                                const SizedBox(height: 16),
                                Row(
                              children: [
                                    Expanded(
                                      child: TextField(
                                        controller: taskController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter task...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final taskText = taskController.text.trim();
                                        if (taskText.isEmpty) return;
                                        
                                        // Show date picker
                                        final selectedDate = await showThemedDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                        );
                                        
                                        if (selectedDate != null) {
                                          setState(() {
                                            addedTasks.add({
                                              'task': taskText,
                                              'expect_finish': selectedDate,
                                            });
                                            taskController.clear();
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFB300),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.all(12),
                                        minimumSize: const Size(56, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Icon(Icons.access_time, size: 24),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // List of added tasks
                                if (addedTasks.isNotEmpty) ...[
                                  Text(
                                    'Added Tasks (${addedTasks.length})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...addedTasks.asMap().entries.map((entry) {
                                  final index = entry.key;
                                    final task = entry.value;
                                  return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task['task'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Expected: ${DateFormat('MMM dd, yyyy').format(task['expect_finish'] as DateTime)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                addedTasks.removeAt(index);
                                              });
                                            },
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red.shade400,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
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
                                    onPressed: addedTasks.isEmpty
                                        ? null
                                        : () {
                                            Navigator.of(dialogContext).pop();
                                            onAdd(addedTasks);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB300),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Add ${addedTasks.length} Task${addedTasks.length != 1 ? 's' : ''}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
            );
          },
        );
      },
    ).then((_) {
      taskController.dispose();
    });
  }

  static Future<void> showMarkTasksDoneDialog({
    required BuildContext context,
    required List<Map<String, dynamic>> undoneTasks,
    required Function(List<String>) onConfirm,
  }) async {
    if (!context.mounted) return;
    
    final Set<String> selectedTaskIds = {};

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Container(
                    width: double.infinity,
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
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Mark Tasks as Done',
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
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 500),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select tasks to mark as done',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...undoneTasks.map((task) {
                                    final taskId = task['task_id']?.toString() ?? '';
                                    final taskText = task['task'] ?? 'Untitled Task';
                                    final isSelected = selectedTaskIds.contains(taskId);
                                    final expectFinish = task['expect_finish'] as String?;
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  selectedTaskIds.remove(taskId);
                                                } else {
                                                  selectedTaskIds.add(taskId);
                                                }
                                              });
                                            },
                                            child: Icon(
                                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                              color: isSelected ? Colors.green : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  taskText,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (expectFinish != null && expectFinish.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Expected: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(expectFinish))}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                  const SizedBox(height: 16),
                                  // Select All / Deselect All buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                  onPressed: () {
                                    setState(() {
                                            if (selectedTaskIds.length == undoneTasks.length) {
                                              selectedTaskIds.clear();
                                            } else {
                                              selectedTaskIds.clear();
                                              for (var task in undoneTasks) {
                                                final taskId = task['task_id']?.toString() ?? '';
                                                if (taskId.isNotEmpty) {
                                                  selectedTaskIds.add(taskId);
                                                }
                                              }
                                            }
                                    });
                                  },
                                        child: Text(
                                          selectedTaskIds.length == undoneTasks.length
                                              ? 'Deselect All'
                                              : 'Select All',
                                    style: TextStyle(color: Colors.blue.shade700),
                                  ),
                                      ),
                                      Text(
                                        '${selectedTaskIds.length} of ${undoneTasks.length} selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                                  // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(),
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
                                        onPressed: selectedTaskIds.isEmpty
                                            ? null
                                            : () {
                                                Navigator.of(dialogContext).pop();
                                                onConfirm(selectedTaskIds.toList());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFB300),
                                    foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          minimumSize: const Size(0, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                        child: Text('Mark ${selectedTaskIds.length} Task${selectedTaskIds.length != 1 ? 's' : ''} as Done'),
                                ),
                              ],
                            ),
                          ],
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget buildRecentActivityFeed({
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> photos,
    List<Map<String, dynamic>>? payments,
    int maxItems = 5,
  }) {
    List<Map<String, dynamic>> activities = [];

    for (var task in tasks) {
      final createdAt = task['created_at'] ?? DateTime.now().toIso8601String();
      final taskDone = task['task_done'];
      final isDone = task['done'] == true;
      
      if (isDone && taskDone != null && taskDone.toString().isNotEmpty) {
        activities.add({
          'type': 'task_done',
          'title': 'Task completed',
          'description': task['task'] ?? 'Unknown task',
          'timestamp': taskDone.toString(),
          'icon': Icons.check_circle,
        });
      }
      
      // Always add task creation activity
      activities.add({
        'type': 'task_added',
        'title': 'Task added',
        'description': task['task'] ?? 'New task',
        'timestamp': createdAt,
        'icon': Icons.playlist_add,
      });
    }

    for (var payment in payments ?? const []) {
      final createdAtRaw = payment['paid_at'] ?? payment['created_at'];
      final createdAt = createdAtRaw is DateTime
          ? createdAtRaw.toIso8601String()
          : (createdAtRaw?.toString() ?? DateTime.now().toIso8601String());
      final amount = (payment['amount'] as num?)?.toDouble();
      final formattedAmount = amount != null ? amount.toStringAsFixed(2) : null;
      final paymentType = (payment['payment_type'] ?? payment['type'] ?? 'payment').toString();
      final isMilestone = paymentType.toLowerCase().contains('milestone');
      final milestoneLabel = payment['milestone_description'] ?? payment['description'];

      String description;
      if (isMilestone && milestoneLabel != null && milestoneLabel.toString().trim().isNotEmpty) {
        description = milestoneLabel.toString();
      } else if (payment['description'] != null && payment['description'].toString().trim().isNotEmpty) {
        description = payment['description'].toString().trim();
      } else {
        description = isMilestone ? 'Milestone payment received' : 'Payment received';
      }

      final subtitle = formattedAmount != null
          ? '₱$formattedAmount${isMilestone ? ' • $description' : ''}'
          : description;

      activities.add({
        'type': 'payment',
        'title': isMilestone ? 'Milestone payment received' : 'Payment received',
        'description': subtitle,
        'timestamp': createdAt,
        'icon': isMilestone ? Icons.payments : Icons.account_balance_wallet,
      });
    }

    for (var report in reports) {
      activities.add({
        'type': 'report',
        'title': 'Progress report added',
        'description': (report['content'] ?? '').length > 50 
            ? '${(report['content'] ?? '').substring(0, 50)}...'
            : report['content'] ?? 'No content',
        'timestamp': report['created_at'] ?? DateTime.now().toIso8601String(),
        'icon': Icons.description,
      });
    }

    for (var photo in photos) {
      activities.add({
        'type': 'photo',
        'title': 'Photo uploaded',
        'description': 'Project photo uploaded',
        'timestamp': photo['created_at'] ?? DateTime.now().toIso8601String(),
        'icon': Icons.photo_camera,
      });
    }

    activities.sort((a, b) {
      try {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      } catch (e) {
        return 0;
      }
    });

    activities = activities.take(maxItems).toList();

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No recent activity'),
        ),
      );
    }

    return Column(
      children: activities.map((activity) => _buildActivityItem(activity)).toList(),
    );
  }

  static Widget _buildActivityItem(Map<String, dynamic> activity) {
    String timeAgo = _getTimeAgo(activity['timestamp']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Icon(
            activity['icon'],
            color: Colors.grey[700],
            size: 20,
          ),
        ),
        title: Text(
          activity['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity['description'],
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
      ),
    );
  }

  static String _getTimeAgo(String timestamp) {
    try {
      final DateTime activityTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(activityTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
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

  static Widget buildProjectHeaderWithActivity({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    String? estimatedCompletion,
    required int? duration,
    required bool isCustomContract,
    required double progress,
    String? contractStatusLabel,
    Color? contractStatusColor,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> photos,
    VoidCallback? onRefresh,
    VoidCallback? onEditCompletion,
    VoidCallback? onSwitchProject,
    VoidCallback? onViewContract,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 320,
            child: buildProjectHeader(
              projectTitle: projectTitle,
              clientName: clientName,
              address: address,
              startDate: startDate,
              estimatedCompletion: estimatedCompletion,
              duration: duration,
              isCustomContract: isCustomContract,
              progress: progress,
              contractStatusLabel: contractStatusLabel,
              contractStatusColor: contractStatusColor,
              onViewContract: onViewContract,
              onRefresh: onRefresh,
              onEditCompletion: onEditCompletion,
              onSwitchProject: onSwitchProject,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: 320,
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
                        Icon(Icons.timeline, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: buildRecentActivityFeed(
                            tasks: tasks,
                            reports: reports,
                            photos: photos,
                            maxItems: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    String? contractStatusLabel,
    Color? contractStatusColor,
    VoidCallback? onViewContract,
    required String selectedTab,
    required Function(String) onTabChanged,
    required Widget tabContent,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> photos,
    VoidCallback? onRefresh,
    VoidCallback? onEditCompletion, 
    VoidCallback? onSwitchProject,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          buildProjectHeaderWithActivity(
            projectTitle: projectTitle,
            clientName: clientName,
            address: address,
            startDate: startDate,
            estimatedCompletion: estimatedCompletion,
            duration: duration,
            isCustomContract: isCustomContract, 
            progress: progress,
            contractStatusLabel: contractStatusLabel,
            contractStatusColor: contractStatusColor,
            tasks: tasks,
            reports: reports,
            photos: photos,
            onRefresh: onRefresh,
            onEditCompletion: onEditCompletion,
            onSwitchProject: onSwitchProject,
            onViewContract: onViewContract,
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
    String? contractStatusLabel,
    Color? contractStatusColor,
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
    VoidCallback? onViewContract,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          buildProjectHeaderWithActivity(
            projectTitle: projectTitle,
            clientName: clientName,
            address: address,
            startDate: startDate,
            estimatedCompletion: estimatedCompletion,
            duration: duration, 
            isCustomContract: isCustomContract,
            progress: progress,
            contractStatusLabel: contractStatusLabel,
            contractStatusColor: contractStatusColor,
            tasks: tasks,
            reports: reports,
            photos: photos,
            onViewContract: onViewContract,
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
                const SizedBox(width: 16),
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
              const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
                    child: CircularProgressIndicator(color: Colors.amber),
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

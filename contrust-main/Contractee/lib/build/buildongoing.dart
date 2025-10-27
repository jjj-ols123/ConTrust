// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CeeOngoingBuildMethods {
  static Widget buildProjectHeader({
    required String projectTitle,
    required String clientName,
    required String address,
    required String startDate,
    required String estimatedCompletion,
    required double progress,
    VoidCallback? onRefresh,
    VoidCallback? onChat,
    bool canChat = false,
    VoidCallback? onPayment,
    bool isPaid = false,
    VoidCallback? onViewPaymentHistory,
    String? paymentButtonText,
  }) {
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
                          const Icon(Icons.construction, color: Colors.amber, size: 28),
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
                                  'Contractor: $clientName',
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
                          if (onPayment != null && !isPaid)
                            ElevatedButton.icon(
                              onPressed: onPayment,
                              icon: const Icon(Icons.payment, size: 16),
                              label: Text(paymentButtonText ?? 'Pay Now', style: const TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          if (isPaid) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Paid',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onViewPaymentHistory != null) const SizedBox(width: 8),
                            if (onViewPaymentHistory != null)
                              IconButton(
                                onPressed: onViewPaymentHistory,
                                icon: const Icon(Icons.history, color: Colors.blue, size: 20),
                                tooltip: 'View Payment History',
                              ),
                          ],
                          if (onRefresh != null) const SizedBox(width: 8),
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
                      const Icon(Icons.construction, color: Colors.amber, size: 28),
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
                              'Contractor: $clientName',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onPayment != null && !isPaid)
                        ElevatedButton.icon(
                          onPressed: onPayment,
                          icon: const Icon(Icons.payment, size: 20),
                          label: Text(paymentButtonText ?? 'Proceed to Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      if (isPaid) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onViewPaymentHistory != null) const SizedBox(width: 12),
                        if (onViewPaymentHistory != null)
                          IconButton(
                            onPressed: onViewPaymentHistory,
                            icon: const Icon(Icons.history, color: Colors.blue),
                            tooltip: 'View Payment History',
                          ),
                      ],
                      if (onPayment != null || isPaid) const SizedBox(width: 12),
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
                  'Est. Completion: ',
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
                        color: Colors.amber,
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
    );
  }

  static Widget buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    bool isViewOnly = true,
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
      children: tasks.map((task) => buildTaskItem(task: task)).toList(),
    );
  }

  static Widget buildReportsList({
    required List<Map<String, dynamic>> reports,
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
      children: reports.map((report) => buildReportItem(
        report: report,
        onTap: onViewReport != null ? () => onViewReport(report) : null,
      )).toList(),
    );
  }

  static Widget buildPhotosList({
    required List<Map<String, dynamic>> photos,
    required Future<String?> Function(String?) createSignedUrl,
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

                return GestureDetector(
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
        ...costs.map((cost) => buildCostItem(
          cost: cost,
          onTap: onViewMaterial != null ? () => onViewMaterial(cost) : null,
        )),
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
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
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
        trailing: onTap != null ? const Icon(Icons.visibility) : null,
      ),
    );
  }

  static Widget buildTaskItem({
    required Map<String, dynamic> task,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: task['done'] == true ? Colors.green : Colors.grey[400],
          child: Icon(
            task['done'] == true ? Icons.check : Icons.radio_button_unchecked,
            color: Colors.white,
          ),
        ),
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
      ),
    );
  }

  static Widget buildCostItem({
    required Map<String, dynamic> cost,
    VoidCallback? onTap,
  }) {
    final quantity = (cost['quantity'] as num? ?? 0).toDouble();
    final unitPrice = (cost['unit_price'] as num? ?? 0).toDouble();
    final totalItemCost = quantity * unitPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
            if (onTap != null) const Icon(Icons.visibility),
          ],
        ),
      ),
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
                  color: isActive ? Colors.amber.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.amber.shade700 : Colors.grey.shade600,
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
    VoidCallback? onRefresh,
    VoidCallback? onChat,
    bool canChat = false,
    VoidCallback? onPayment,
    bool isPaid = false,
    VoidCallback? onViewPaymentHistory,
    String? paymentButtonText,
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
            onRefresh: onRefresh,
            onChat: onChat,
            canChat: canChat,
            onPayment: onPayment,
            isPaid: isPaid,
            onViewPaymentHistory: onViewPaymentHistory,
            paymentButtonText: paymentButtonText,
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
    required Future<String?> Function(String?) createSignedUrl,
    Function(Map<String, dynamic>)? onViewReport,
    Function(Map<String, dynamic>)? onViewPhoto,
    Function(Map<String, dynamic>)? onViewMaterial,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    Widget content;
    switch (selectedTab) {
      case 'Tasks':
        content = buildSectionCard(
          title: 'Tasks & Progress',
          icon: Icons.checklist,
          iconColor: Colors.blue,
          child: buildTasksList(tasks: tasks),
        );
        break;
      case 'Reports':
        content = buildSectionCard(
          title: 'Progress Reports',
          icon: Icons.description,
          iconColor: Colors.orange,
          child: buildReportsList(
            reports: reports,
            onViewReport: onViewReport,
          ),
        );
        break;
      case 'Photos':
        content = buildSectionCard(
          title: 'Project Photos',
          icon: Icons.photo_library,
          iconColor: Colors.green,
          child: buildPhotosList(
            photos: photos,
            createSignedUrl: createSignedUrl,
            onViewPhoto: onViewPhoto,
          ),
        );
        break;
      case 'Materials':
        content = buildSectionCard(
          title: 'Materials & Costs',
          icon: Icons.construction,
          iconColor: Colors.purple,
          child: buildCostsList(
            costs: costs,
            onViewMaterial: onViewMaterial,
          ),
        );
        break;
      default:
        content = buildSectionCard(
          title: 'Tasks & Progress',
          icon: Icons.checklist,
          iconColor: Colors.blue,
          child: buildTasksList(tasks: tasks),
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
    required double progress,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> photos,
    required List<Map<String, dynamic>> costs,
    required Future<String?> Function(String?) createSignedUrl,
    Function(Map<String, dynamic>)? onViewReport,
    Function(Map<String, dynamic>)? onViewPhoto,
    Function(Map<String, dynamic>)? onViewMaterial,
    VoidCallback? onRefresh,
    VoidCallback? onChat,
    bool canChat = false,
    VoidCallback? onPayment,
    bool isPaid = false,
    VoidCallback? onViewPaymentHistory,
    String? paymentButtonText,
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
            onRefresh: onRefresh,
            onChat: onChat,
            canChat: canChat,
            onPayment: onPayment,
            isPaid: isPaid,
            onViewPaymentHistory: onViewPaymentHistory,
            paymentButtonText: paymentButtonText,
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
                          child: buildDesktopTasksList(tasks: tasks),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildGridSectionCard(
                          title: 'Project Photos',
                          icon: Icons.photo_library,
                          iconColor: Colors.green,
                          child: buildDesktopPhotosList(
                            photos: photos,
                            createSignedUrl: createSignedUrl,
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
                          iconColor: Colors.orange,
                          child: buildDesktopReportsList(
                            reports: reports,
                            onViewReport: onViewReport,
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
                            onViewMaterial: onViewMaterial,
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
              Icon(
                task['done'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task['done'] == true ? Colors.green : Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['task'] ?? '',
                      style: TextStyle(
                        decoration: task['done'] == true ? TextDecoration.lineThrough : null,
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
            ],
          ),
        );
      },
    );
  }

  static Widget buildDesktopReportsList({
    required List<Map<String, dynamic>> reports,
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
                if (onViewReport != null) const Icon(Icons.visibility, size: 16),
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
            return GestureDetector(
              onTap: onViewPhoto != null ? () => onViewPhoto(photo) : null,
              child: Container(
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
            );
          },
        );
      },
    );
  }

  static Widget buildDesktopCostsList({
    required List<Map<String, dynamic>> costs,
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
              
              return InkWell(
                onTap: onViewMaterial != null ? () => onViewMaterial(cost) : null,
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
                      const SizedBox(width: 4),
                      if (onViewMaterial != null) const Icon(Icons.visibility, size: 14),
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

  static void showReportDialog(BuildContext context, Map<String, dynamic> report) {
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
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
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

  static void showPhotoDialog(BuildContext context, Map<String, dynamic> photo, Future<String?> Function(String?) createSignedUrl) {
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
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
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
                      child: snapshot.hasData && snapshot.data != null
                          ? InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Image.network(
                                snapshot.data!,
                                fit: BoxFit.contain,
                                width: MediaQuery.of(context).size.width * 0.95,
                                height: MediaQuery.of(context).size.height * 0.7,
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

  static void showMaterialDetailsDialog(BuildContext context, Map<String, dynamic> material) {
    final name = material['material_name'] ?? material['name'] ?? 'Unknown Material';
    final brand = material['brand'] ?? '';
    final qty = material['quantity'] ?? material['qty'] ?? 0;
    final unit = material['unit'] ?? 'pcs';
    final unitPrice = material['unit_price'] ?? material['unitPrice'] ?? 0;
    final total = material['total'] ?? ((qty as num) * (unitPrice as num));
    final notes = material['notes'] ?? material['note'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

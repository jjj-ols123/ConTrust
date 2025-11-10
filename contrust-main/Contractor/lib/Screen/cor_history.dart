// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:backend/services/contractor services/cor_profileservice.dart';
import 'package:backend/utils/be_status.dart';
import 'package:backend/services/both services/be_receipt_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html if (dart.library.html) 'dart:html';
import 'dart:ui_web' as ui_web if (dart.library.html) 'dart:ui_web';

class CorHistoryPage extends StatefulWidget {
  final String contractorId;

  const CorHistoryPage({super.key, required this.contractorId});

  @override
  State<CorHistoryPage> createState() => _CorHistoryPageState();
}

class _CorHistoryPageState extends State<CorHistoryPage> {
  String selectedTab = 'Projects';
  
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredProjects = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  
  final TextEditingController projectSearchController = TextEditingController();
  final TextEditingController transactionSearchController = TextEditingController();
  
  String selectedProjectStatus = 'All';
  String selectedPaymentType = 'All';
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    projectSearchController.addListener(_filterProjects);
    transactionSearchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    projectSearchController.dispose();
    transactionSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      
      final supabase = Supabase.instance.client;
      
      final projectsResponse = await supabase
          .from('Projects')
          .select('*')
          .eq('contractor_id', widget.contractorId)
          .order('created_at', ascending: false);
      
      final transactionsResponse = await CorProfileService().loadTransactions(widget.contractorId);
      
      setState(() {
        projects = List<Map<String, dynamic>>.from(projectsResponse);
        transactions = List<Map<String, dynamic>>.from(transactionsResponse);
        filteredProjects = projects;
        filteredTransactions = transactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading history data: $e');
    }
  }

  void _filterProjects() {
    final query = projectSearchController.text.toLowerCase();
    setState(() {
      filteredProjects = projects.where((project) {
        final matchesSearch = query.isEmpty ||
            (project['title']?.toString().toLowerCase().contains(query) ?? false) ||
            (project['type']?.toString().toLowerCase().contains(query) ?? false);
        
        final matchesStatus = selectedProjectStatus == 'All' ||
            project['status']?.toString().toLowerCase() == selectedProjectStatus.toLowerCase();
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _filterTransactions() {
    final query = transactionSearchController.text.toLowerCase();
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        final matchesSearch = query.isEmpty ||
            (transaction['project_title']?.toString().toLowerCase().contains(query) ?? false);
        
        final matchesType = selectedPaymentType == 'All' ||
            transaction['payment_type']?.toString().toLowerCase() == selectedPaymentType.toLowerCase();
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _onProjectStatusChanged(String status) {
    setState(() {
      selectedProjectStatus = status;
    });
    _filterProjects();
  }

  void _onPaymentTypeChanged(String type) {
    setState(() {
      selectedPaymentType = type;
    });
    _filterTransactions();
  }


  void _onProjectTap(Map<String, dynamic> project) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildProjectDetailsDialog(dialogContext, project),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildProjectDetailsDialog(BuildContext dialogContext, Map<String, dynamic> project) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Header
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
                      Icons.folder_open,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project['title'] ?? 'Project Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(project['status']).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(project['status']),
                            size: 14,
                            color: _getStatusColor(project['status']),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusLabel(project['status']),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(project['status']),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Builder(
                      builder: (context) {
                        final fields = <Widget>[
                          _buildDetailField('Type', project['type'] ?? 'Not specified'),
                          _buildDetailField('Location', project['location'] ?? 'Not specified'),
                          _buildDetailField('Budget', _formatBudget(project)),
                          _buildDetailField('Start Date', _formatStartDate(project)),
                          if (project['created_at'] != null)
                            _buildDetailField('Created', _getTimeAgo(DateTime.parse(project['created_at']))),
                        ];

                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: fields,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: _buildDetailField('Description', project['description'] ?? 'No description provided'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
            fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        const SizedBox(height: 6),
          Container(
            width: double.infinity,
          padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: TextStyle(
              fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
    );
  }

  String _formatBudget(Map<String, dynamic> project) {
    final minBudget = project['min_budget'];
    final maxBudget = project['max_budget'];
    
    if (minBudget != null && maxBudget != null) {
      return '₱$minBudget - ₱$maxBudget';
    } else if (minBudget != null) {
      return '₱$minBudget';
    } else if (maxBudget != null) {
      return '₱$maxBudget';
    }
    return 'Not specified';
  }

  String _formatStartDate(Map<String, dynamic> project) {
    return project['start_date'] != null
        ? _formatDate(project['start_date'])
        : 'Not specified';
  }

  Color _getStatusColor(String? status) {
    return ProjectStatus().getStatusColor(status);
  }

  IconData _getStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  String _getStatusLabel(String? status) {
    return ProjectStatus().getStatusLabel(status);
  }

  Widget _buildTabNavigation() {
    final tabs = ['Projects', 'Payments'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = selectedTab == tab;
          final isFirst = index == 0;
          final isLast = index == tabs.length - 1;
          
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.amber.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                    bottomLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                    topRight: isLast ? const Radius.circular(8) : Radius.zero,
                    bottomRight: isLast ? const Radius.circular(8) : Radius.zero,
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (selectedTab) {
      case 'Projects':
        return _buildProjectsSection();
      case 'Payments':
        return _buildPaymentsSection();
      default:
        return _buildProjectsSection();
    }
  }

  Widget _buildProjectsSection() {
    // Sort projects: non-completed/cancelled on top
    final sortedProjects = List<Map<String, dynamic>>.from(filteredProjects);
    sortedProjects.sort((a, b) {
      final statusA = (a['status'] ?? '').toString().toLowerCase();
      final statusB = (b['status'] ?? '').toString().toLowerCase();
      
      // Priority: active projects first, then by date
      bool isActiveA = statusA != 'completed' && statusA != 'cancelled';
      bool isActiveB = statusB != 'completed' && statusB != 'cancelled';
      
      if (isActiveA && !isActiveB) return -1;
      if (!isActiveA && isActiveB) return 1;
      
      // If same active status, sort by created date (newest first)
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Project History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: projectSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedProjectStatus,
                items: ['All', 'Active', 'Completed', 'Cancelled', 'Pending']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => _onProjectStatusChanged(value ?? 'All'),
                underline: Container(),
                icon: const Icon(Icons.filter_list, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No projects found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: sortedProjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = sortedProjects[index];
                      return _buildProjectCard(project);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.amber.shade700, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: transactionSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedPaymentType,
                items: ['All', 'Deposit', 'Final', 'Milestone']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => _onPaymentTypeChanged(value ?? 'All'),
                underline: Container(),
                icon: const Icon(Icons.filter_list, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No transactions found', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['status']?.toString();
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);
    
    return InkWell(
      onTap: () => _onProjectTap(project),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project['title'] ?? 'Untitled Project',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['type'] ?? 'No type',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (project['created_at'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Created ${_getTimeAgo(DateTime.parse(project['created_at']))}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return InkWell(
      onTap: () => _showPaymentDetailsDialog(transaction),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.payment, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['project_title'] ?? 'Untitled',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction['payment_type'] ?? 'Payment',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              '₱${transaction['amount'] ?? 0}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetailsDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildPaymentDetailsDialog(dialogContext, transaction),
    );
  }

  Widget _buildPaymentDetailsDialog(BuildContext dialogContext, Map<String, dynamic> transaction) {
    final receiptPath = transaction['receipt_path'] as String?;
    final hasReceipt = receiptPath != null && receiptPath.isNotEmpty;
    final amountValue = (transaction['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final paymentType = transaction['payment_type'] ?? 'Payment';
    final reference = transaction['reference'] ?? 'N/A';
    final clientName = transaction['client_name'] ?? 'Unknown client';
    final paymentDate = _formatDate(transaction['payment_date']);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black.withOpacity(0.5),
            width: 0.5,
          ),
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
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Payment Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                    if (hasReceipt) ...[
                      Text(
                        'Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 320, maxHeight: 480),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<String?>(
                            future: ReceiptService.getReceiptSignedUrl(receiptPath!, expirationSeconds: 3600),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Unable to load the receipt at this time.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return _buildPdfViewer(snapshot.data!);
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          'No e-receipt was provided for this transaction.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildDetailField('Project', transaction['project_title'] ?? 'Unknown project'),
                    _buildDetailField('Payment Type', paymentType),
                    _buildDetailField('Amount Received', '₱$amountValue'),
                    _buildDetailField('Reference', reference),
                    _buildDetailField('Client', clientName),
                    _buildDetailField('Payment Date', paymentDate),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }


  Widget _buildPdfViewer(String pdfUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: kIsWeb
            ? _buildWebPdfViewer(pdfUrl)
            : _buildMobilePdfViewer(pdfUrl),
      ),
    );
  }

  Widget _buildWebPdfViewer(String pdfUrl) {
    if (!kIsWeb) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade50,
        child: const Center(
          child: Text('PDF viewer not available on this platform'),
        ),
      );
    }
    
    final viewType = 'pdf-viewer-${pdfUrl.hashCode.abs()}';
    
    try {
      if (kIsWeb) {
        ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
          final iframe = html.IFrameElement()
            ..src = pdfUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'fullscreen'
            ..onError.listen((event) {});
          
          return iframe;
        });
      }
    } catch (e) {
      //
    }
    
    return HtmlElementView(viewType: viewType);
  }

  Widget _buildMobilePdfViewer(String pdfUrl) {
    return SfPdfViewer.network(
      pdfUrl,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load PDF: ${details.error}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : isDesktop
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildProjectsSection(),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildPaymentsSection(),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildTabNavigation(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _buildCurrentTabContent(),
                      ),
                    ),
                  ],
                ),
    );
  }
}

  
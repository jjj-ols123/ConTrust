// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_payment_service.dart';
import 'package:backend/models/be_payment_modal.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/build/buildongoing.dart';
import 'package:contractee/build/buildceeprofile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CeeOngoingProjectScreen extends StatefulWidget {
  final String projectId;
  const CeeOngoingProjectScreen({super.key, required this.projectId});

  @override
  State<CeeOngoingProjectScreen> createState() => _CeeOngoingProjectScreenState();
}

class _CeeOngoingProjectScreenState extends State<CeeOngoingProjectScreen> {
  final TextEditingController reportController = TextEditingController();
  final TextEditingController costAmountController = TextEditingController();
  final TextEditingController costNoteController = TextEditingController();
  final TextEditingController progressController = TextEditingController();

  bool isEditing = false;
  String selectedTab = 'Tasks'; 

  final _fetchService = FetchService();
  final _paymentService = PaymentService();
  final supabase = Supabase.instance.client;
  String? _chatRoomId;
  bool _canChat = false;
  Map<String, dynamic>? _contractorData;

  Map<String, dynamic>? projectData;
  List<Map<String, dynamic>> _localTasks = [];
  double _localProgress = 0.0;
  bool isLoading = true;
  bool _isPaid = false;
  Map<String, dynamic>? _paymentSummary;

  @override
  void initState() {
    super.initState();
    loadData();
    _getChatRoomId();
    _checkChatPermission();
    _loadContractorData();
  }

  @override
  void dispose() {
    reportController.dispose();
    costAmountController.dispose();
    costNoteController.dispose();
    progressController.dispose();
    super.dispose();
  }

  Future<void> _getChatRoomId() async {
    try {
      final chatRoomId = await _fetchService.fetchChatRoomId(widget.projectId);
      setState(() {
        _chatRoomId = chatRoomId;
      });
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error getting chatroom_id:');
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
      ConTrustSnackBar.error(context, 'Error checking chat permission: ');
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
      ConTrustSnackBar.error(context, 'Error loading contractor data: ');
    }
  }

  Map<String, dynamic>? _contractData;

  void loadData() async {
    try {
      setState(() => isLoading = true);
      
      final data = await _fetchService.fetchProjectDetails(widget.projectId);
      final tasks = await _fetchService.fetchProjectTasks(widget.projectId);
      final isPaid = await _paymentService.isProjectPaid(widget.projectId);
      final paymentSummary = await _paymentService.getPaymentSummary(widget.projectId);
      
      Map<String, dynamic>? contractData;
      final contractId = data?['contract_id'];
      if (contractId != null) {
        try {
          final contract = await Supabase.instance.client
              .from('Contracts')
              .select()
              .eq('contract_id', contractId)
              .maybeSingle();
          contractData = contract;
        } catch (_) {}
      }
      
      setState(() {
        projectData = data;
        _contractData = contractData;
        _localTasks = tasks;
        _localProgress = (data?['progress'] as num?)?.toDouble() ?? 0.0;
        _isPaid = isPaid;
        _paymentSummary = paymentSummary;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error loading project data. Please try again. $e');
      }
    }
  }

  void onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  Future<String?> createSignedPhotoUrl(String? path) async {
    if (path == null) return null;
    try {
      final response = await supabase.storage
          .from('projectphotos')
          .createSignedUrl(path, 60 * 60 * 24);
      return response;
    } catch (e) {
      return null;
    }
  }

  void onViewReport(Map<String, dynamic> report) {
    CeeOngoingBuildMethods.showReportDialog(context, report);
  }

  void onViewPhoto(Map<String, dynamic> photo) {
    CeeOngoingBuildMethods.showPhotoDialog(context, photo, createSignedPhotoUrl);
  }

  void onViewMaterial(Map<String, dynamic> material) {
    CeeOngoingBuildMethods.showMaterialDetailsDialog(context, material);
  }

  Future<void> _showPaymentHistory() async {
    try {
      final payments = await _paymentService.getPaymentHistory(widget.projectId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
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
                        child: const Icon(Icons.history, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Payment History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
                if (_paymentSummary != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),    
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(
                              '₱${(_paymentSummary!['total_paid'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        if (_paymentSummary!['total_amount'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Contract Amount:', style: TextStyle(fontSize: 14)),
                              Text(
                                '₱${(_paymentSummary!['total_amount'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining:', style: TextStyle(fontSize: 14)),
                              Text(
                                '₱${(_paymentSummary!['remaining'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: double.parse(_paymentSummary!['percentage_paid'] ?? '0') / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_paymentSummary!['percentage_paid']}% Paid',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                Flexible(
                  child: payments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No payments yet', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(20),
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[payments.length - 1 - index];
                            final date = DateTime.parse(payment['date']).toLocal();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Icon(Icons.check_circle, color: Colors.green.shade700),
                                ),
                                title: Text(
                                  '₱${(payment['amount'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                subtitle: Text(
                                  '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  'Payment #${payments.length - index}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error loading payment history: $e');
    }
  }

  void _navigateToChat() async {
    if (!_canChat) return;
    
    final project = projectData!;
    final contracteeId = project['contractee_id'] ?? '';
    final contractorId = project['contractor_id'] ?? '';
    final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
    final contractorPhoto = _contractorData?['profile_photo'] ?? '';

    String? chatRoomId = _chatRoomId;
    if (chatRoomId == null) {
      try {
        chatRoomId = await FetchService().fetchChatRoomId(widget.projectId);
        if (chatRoomId == null) {
          ConTrustSnackBar.error(context, 'Unable to access chat room');
          return;
        }
      } catch (e) {
        ConTrustSnackBar.error(context, 'Error accessing chat: $e');
        return;
      }
    }

    context.go('/chat/${Uri.encodeComponent(contractorName)}', extra: {
      'chatRoomId': chatRoomId,
      'contracteeId': contracteeId,
      'contractorId': contractorId,
      'contractorProfile': contractorPhoto,
    });
  }

  Future<void> _handlePayment() async {
    try {
      final project = projectData!;
      final projectTitle = project['title'] ?? 'Untitled Project';
      
      final paymentInfo = await _paymentService.getPaymentInfo(widget.projectId);
      
      final contractType = paymentInfo['contract_type'] as String?;
      final requiresCustomAmount = paymentInfo['requires_custom_amount'] == true;
      
      double? customAmount;
      double amount;
      
      if (requiresCustomAmount) {

        customAmount = await _showAmountInputDialog(contractType);
        if (customAmount == null) return;
        amount = customAmount;
      } else {
  
        amount = (paymentInfo['amount'] as num).toDouble();
      }

  
      await PaymentModal.show(
        context: context,
        projectId: widget.projectId,
        projectTitle: projectTitle,
        amount: amount,
        customAmount: customAmount, 
        onPaymentSuccess: () {
          loadData();
        },
      );
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error processing payment: $e');
    }
  }

  Future<double?> _showAmountInputDialog(String? contractType) async {
    final controller = TextEditingController();
    String dialogTitle = 'Enter Payment Amount';
    String dialogMessage = 'Please specify the payment amount for this project.';
    
  
    if (contractType == 'time_and_materials') {
      dialogTitle = 'Time & Materials Payment';
      dialogMessage = 'Enter the payment amount based on hours worked and materials used.';
    } else if (contractType == 'cost_plus') {
      dialogTitle = 'Cost Plus Payment';
      dialogMessage = 'Enter the payment amount based on actual costs plus overhead.';
    } else if (contractType == 'custom') {
      dialogTitle = 'Custom Contract Payment';
      dialogMessage = 'Enter the payment amount as agreed in the custom contract.';
    }
    
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
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
                        Icons.payments,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dialogTitle,
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dialogMessage,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        helperText: 'Minimum: ₱100.00',
                        helperStyle: TextStyle(color: Colors.grey.shade600),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) {
                                ConTrustSnackBar.warning(context, 'Please enter an amount');
                                return;
                              }
                              
                              final amount = double.tryParse(text);
                              if (amount == null) {
                                ConTrustSnackBar.error(context, 'Invalid amount format');
                                return;
                              }
                              
                              if (amount < 100) {
                                ConTrustSnackBar.warning(context, 'Minimum payment amount is ₱100.00');
                                return;
                              }
                              
                              Navigator.pop(context, amount);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber,))
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
    final project = projectData!;
    final projectTitle = project['title'] ?? 'Project';
    final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
    final address = project['location'] ?? '';
    
    String startDate = project['start_date'] ?? '';
    if (startDate.isEmpty && _contractData != null && _contractData!['type'] == 'custom') {
      try {
        final fieldValues = _contractData!['field_values'];
        if (fieldValues != null && fieldValues is Map) {
          final startDateValue = fieldValues['Project.StartDate'];
          if (startDateValue != null && startDateValue.toString().isNotEmpty) {
            startDate = startDateValue.toString();
          }
        }
      } catch (_) {}
    }
    
    final estimatedCompletion = project['estimated_completion'] ?? '';
    final duration = project['duration'] as int?;
    final projectStatus = project['status'] ?? '';

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: Column(
        children: [
          CeeProfileBuildMethods.buildHeader(context, 'Ongoing Project'),
          Expanded(
            child: CeeOngoingBuildMethods.buildMobileLayout(
              projectTitle: projectTitle,
              clientName: contractorName,
              address: address,
              startDate: startDate,
              estimatedCompletion: estimatedCompletion,
              duration: duration,
        progress: _localProgress,
        selectedTab: selectedTab,
        onTabChanged: onTabChanged,
        onRefresh: loadData,
        onChat: _canChat && _chatRoomId != null ? _navigateToChat : null,
        canChat: _canChat,
        onPayment: projectStatus == 'active' ? _handlePayment : null,
        isPaid: _isPaid,
        onViewPaymentHistory: _isPaid ? _showPaymentHistory : null,
        paymentButtonText: _paymentSummary?['payment_status'] == 'partial' ? 'Make Payment' : null,
        tabContent: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    final project = projectData!;
    final projectTitle = project['title'] ?? 'Project';
    final contractorName = _contractorData?['firm_name'] ?? 'Contractor';
    final address = project['location'] ?? '';
    
    String startDate = project['start_date'] ?? '';
    if (startDate.isEmpty && _contractData != null && _contractData!['type'] == 'custom') {
      try {
        final fieldValues = _contractData!['field_values'];
        if (fieldValues != null && fieldValues is Map) {
          final startDateValue = fieldValues['Project.StartDate'];
          if (startDateValue != null && startDateValue.toString().isNotEmpty) {
            startDate = startDateValue.toString();
          }
        }
      } catch (_) {}
    }
    
    final estimatedCompletion = project['estimated_completion'] ?? '';
    final duration = project['duration'] as int?;
    final projectStatus = project['status'] ?? '';

    return RefreshIndicator(
      onRefresh: () async => loadData(),
      child: Column(
        children: [
          CeeProfileBuildMethods.buildHeader(context, 'Ongoing Project'),
          Expanded(
            child: FutureBuilder<List<List<Map<String, dynamic>>>>(
              future: _getTabData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }

                final data = snapshot.data ?? [[], [], []];
                final reports = data[0];
                final photos = data[1];
                final costs = data[2];

                return CeeOngoingBuildMethods.buildDesktopGridLayout(
                  context: context,
                  projectTitle: projectTitle,
                  clientName: contractorName,
                  address: address,
                  startDate: startDate,
                  estimatedCompletion: estimatedCompletion,
                  duration: duration,
                  progress: _localProgress,
                  tasks: _localTasks,
                  reports: reports,
            photos: photos,
            costs: costs,
            createSignedUrl: createSignedPhotoUrl,
            onViewReport: onViewReport,
            onViewPhoto: onViewPhoto,
            onViewMaterial: onViewMaterial,
            onRefresh: loadData,
            onChat: _canChat && _chatRoomId != null ? _navigateToChat : null,
            canChat: _canChat,
            onPayment: projectStatus == 'active' ? _handlePayment : null,
            isPaid: _isPaid,
            onViewPaymentHistory: _isPaid ? _showPaymentHistory : null,
            paymentButtonText: _paymentSummary?['payment_status'] == 'partial' ? 'Make Payment' : null,
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: _getTabData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        final data = snapshot.data ?? [[], [], []];
        final reports = data[0];
        final photos = data[1];
        final costs = data[2];

        return CeeOngoingBuildMethods.buildTabContent(
          context: context,
          selectedTab: selectedTab,
          tasks: _localTasks,
          reports: reports,
          photos: photos,
          costs: costs,
          createSignedUrl: createSignedPhotoUrl,
          onViewReport: onViewReport,
          onViewPhoto: onViewPhoto,
          onViewMaterial: onViewMaterial,
                                  );
                                },
                              );
  }

  Future<List<List<Map<String, dynamic>>>> _getTabData() async {
    try {
      final reports = await _fetchService.fetchProjectReports(widget.projectId);
      final photos = await _fetchService.fetchProjectPhotos(widget.projectId);
      final costs = await _fetchService.fetchProjectCosts(widget.projectId);
      return [reports, photos, costs];
    } catch (e) {
      return [[], [], []];
    }
  }
}

// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:async';
import 'package:backend/services/both services/be_fetchservice.dart';
import 'package:backend/services/both services/be_payment_service.dart';
import 'package:backend/models/be_payment_modal.dart';
import 'package:backend/utils/be_constraint.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:contractee/build/buildongoing.dart';
import 'package:contractee/pages/cee_project_dashboard.dart';
import 'package:flutter/material.dart';
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

  Map<String, dynamic>? projectData;
  bool isLoading = true;
  bool _isPaid = false;
  Map<String, dynamic>? _paymentSummary;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _debounceTimer;
  StreamController<Map<String, dynamic>>? _controller;
  Stream<Map<String, dynamic>>? _projectStream;
  bool _isRetryingRealtime = false;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _disposeRealtime();
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _projectStream = _controller!.stream;
    _attachRealtimeListeners();
    _emitAggregatedData();
    _getChatRoomId();
  }

  void _debouncedEmitAggregatedData() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _emitAggregatedData();
    });
  }

  @override
  void dispose() {
    _disposeRealtime();
    reportController.dispose();
    costAmountController.dispose();
    costNoteController.dispose();
    progressController.dispose();
    super.dispose();
  }

  void _disposeRealtime() {
    _debounceTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _controller?.close();
    _controller = null;
    _isRetryingRealtime = false;
  }

  void _attachRealtimeListeners() {
    final supabase = Supabase.instance.client;
    
    void safeListen(Stream stream, String tableName) {
      _subscriptions.add(
        stream.listen(
          (_) => _debouncedEmitAggregatedData(),
          onError: (error) {
            if (mounted && !_isRetryingRealtime) {
              debugPrint('Realtime subscription error for $tableName: $error');
              _isRetryingRealtime = true;
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  for (final sub in _subscriptions) {
                    sub.cancel();
                  }
                  _subscriptions.clear();
                  _isRetryingRealtime = false;
                  _attachRealtimeListeners();
                } else {
                  _isRetryingRealtime = false;
                }
              });
            }
          },
          cancelOnError: false,
        ),
      );
    }
    
    try {
      safeListen(
        supabase
            .from('Projects')
            .stream(primaryKey: ['project_id'])
            .eq('project_id', widget.projectId),
        'Projects',
      );
      safeListen(
        supabase
            .from('ProjectTasks')
            .stream(primaryKey: ['task_id'])
            .eq('project_id', widget.projectId),
        'ProjectTasks',
      );
      safeListen(
        supabase
            .from('ProjectReports')
            .stream(primaryKey: ['report_id'])
            .eq('project_id', widget.projectId),
        'ProjectReports',
      );
      safeListen(
        supabase
            .from('ProjectPhotos')
            .stream(primaryKey: ['photo_id'])
            .eq('project_id', widget.projectId),
        'ProjectPhotos',
      );
      safeListen(
        supabase
            .from('ProjectMaterials')
            .stream(primaryKey: ['material_id'])
            .eq('project_id', widget.projectId),
        'ProjectMaterials',
      );
      safeListen(
        supabase
            .from('Contracts')
            .stream(primaryKey: ['contract_id'])
            .eq('project_id', widget.projectId),
        'Contracts',
      );
    } catch (e) {
      debugPrint('Error setting up realtime listeners: $e');
    }
  }

  Future<void> _emitAggregatedData() async {
    try {
      final data = await _loadProjectData();
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
    } catch (e) {
      // 
    }
  }

  Future<Map<String, dynamic>> _loadProjectData() async {
    final projectDetails = await _fetchService.fetchProjectDetails(widget.projectId);
    if (projectDetails == null) {
      return {
        'projectDetails': {},
        'tasks': [],
        'reports': [],
        'photos': [],
        'costs': [],
        'contracts': [],
        'progress': 0.0,
      };
    }

    final tasks = await _fetchService.fetchProjectTasks(widget.projectId);
    final reports = await _fetchService.fetchProjectReports(widget.projectId);
    final photos = await _fetchService.fetchProjectPhotos(widget.projectId);
    final costs = await _fetchService.fetchProjectCosts(widget.projectId);

    Map<String, dynamic>? contractData;
    final contractId = projectDetails['contract_id'];
    if (contractId != null) {
      try {
        contractData = await _fetchService.fetchContractWithDetails(
          contractId,
          contracteeId: supabase.auth.currentUser?.id,
        );
      } catch (e) {
        //
      }
    }

    final progress = (projectDetails['progress'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'projectDetails': projectDetails,
      'tasks': tasks,
      'reports': reports,
      'photos': photos,
      'costs': costs,
      'contracts': contractData != null ? [contractData] : [],
      'progress': progress,
    };
  }

  Future<void> _getChatRoomId() async {
    try {
      await _fetchService.fetchChatRoomId(widget.projectId);
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error getting chatroom_id:');
      }
    }
  }

  Future<void> _checkChatPermission(Map<String, dynamic>? project) async {
    try {
      if (project != null) {
        final contractorId = project['contractor_id'];
        final contracteeId = supabase.auth.currentUser?.id;
        if (contractorId != null && contracteeId != null) {
          await functionConstraint(contractorId, contracteeId);
        }
      }
    } catch (e) {
      if (mounted) {
        ConTrustSnackBar.error(context, 'Error checking chat permission: ');
      }
    }
  }

  Future<void> _loadContractorData(Map<String, dynamic>? project) async {
    try {
      if (project != null) {
        final contractorId = project['contractor_id'];
        if (contractorId != null && contractorId.toString().isNotEmpty) {
          await supabase
              .from('Contractor')
              .select('firm_name, profile_photo')
              .eq('contractor_id', contractorId.toString())
              .maybeSingle();
        }
      }
    } catch (e) {
      debugPrint('Error loading contractor data: $e');
    }
  }

  Future<void> loadData() async {
    try {
      setState(() => isLoading = true);
      
      final results = await Future.wait([
        _loadProjectData(),
        _paymentService.isProjectPaid(widget.projectId),
        _paymentService.getPaymentSummary(widget.projectId),
      ]);
      
      final data = results[0] as Map<String, dynamic>;
      final isPaid = results[1] as bool;
      final paymentSummary = results[2] as Map<String, dynamic>;
      
      final projectDetails = data['projectDetails'] as Map<String, dynamic>?;
      if (projectDetails == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          projectData = null;
        });
        ConTrustSnackBar.error(context, 'Project not found. Please check the project ID.');
      }
        return;
      }
      
      final contracts = data['contracts'] as List?;
      if (contracts != null && contracts.isNotEmpty) {
      }
      
      if (mounted) {
        setState(() {
          projectData = projectDetails;
          _isPaid = isPaid;
          _paymentSummary = paymentSummary;
          isLoading = false;
        });
      }
      
      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
      
      _checkChatPermission(projectDetails);
      _loadContractorData(projectDetails);
    } catch (e) {
      debugPrint('Error in loadData: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          projectData = null;
        });
        ConTrustSnackBar.error(context, 'Error loading project data. Please try again. $e');
      }
    }
  }

  void onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  static const int _signedUrlExpirationSeconds = 60 * 60 * 24;

  Future<String?> createSignedPhotoUrl(String? path) async {
    if (path == null) return null;
    try {
      final response = await supabase.storage
          .from('projectphotos')
          .createSignedUrl(path, _signedUrlExpirationSeconds);
      return response;
    } catch (e) {
      debugPrint('Error creating signed photo URL: $e');
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
                              Builder(
                                builder: (context) {
                                  final contractType = _paymentSummary?['contract_type'] as String? ?? '';
                                  final isMilestone = contractType.toLowerCase().contains('milestone');
                                  return Text(
                                    '₱${(_paymentSummary!['remaining'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isMilestone ? Colors.red : Colors.orange,
                                    ),
                                  );
                                },
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
                            final rawDate = (payment['date'] ?? payment['payment_date'] ?? payment['created_at'] ?? '') as Object?;
                            DateTime? parsed;
                            if (rawDate is String && rawDate.isNotEmpty) {
                              try { 
                                parsed = DateTime.parse(rawDate).toLocal(); 
                              } catch (e) {
                                debugPrint('Error parsing payment date: $e');
                              }
                            }
                            final date = parsed ?? DateTime.now();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Icon(Icons.check_circle, color: Colors.green.shade700),
                                ),
                                title: Text(
                                  '₱${((payment['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
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
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error loading payment history: $e');
    }
  }

  Future<void> _handlePayment() async {
    try {
      final projectDetails = projectData!['projectDetails'] as Map<String, dynamic>? ?? projectData!;
      final projectTitle = (projectDetails['title'] as String?) ?? 'Untitled Project';
      
      final customAmount = await _showAmountInputDialog(null);
        if (customAmount == null) return;
  
      await PaymentModal.show(
        context: context,
        projectId: widget.projectId,
        projectTitle: projectTitle,
        amount: customAmount,
        customAmount: customAmount, 
        onPaymentSuccess: () async {
          await loadData();
          await _emitAggregatedData();
        },
      );
    } catch (e) {
      ConTrustSnackBar.error(context, 'Error processing payment: $e');
    }
  }

  Future<double?> _showAmountInputDialog(String? contractType) async {
    final controller = TextEditingController();
    String dialogTitle = 'Enter Payment Amount';
    String dialogMessage = 'Please enter the amount you want to pay for this project.';
    
    if (contractType != null) {
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
                    Builder(
                      builder: (context) {
                        final contractType = _paymentSummary?['contract_type'] as String? ?? '';
                        final isLumpSum = contractType.toLowerCase().contains('lump') || 
                                         contractType.toLowerCase() == 'lump_sum';
                        final isMilestone = contractType.toLowerCase().contains('milestone');
                        
                        if (!isLumpSum && _paymentSummary != null && _paymentSummary!['remaining'] != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isMilestone ? Colors.red.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isMilestone ? Colors.red.shade200 : Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: isMilestone ? Colors.red.shade700 : Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Amount to be Paid',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${(_paymentSummary!['remaining'] as num).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isMilestone ? Colors.red.shade700 : Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱',
                        hintText: _paymentSummary != null && _paymentSummary!['remaining'] != null
                            ? (_paymentSummary!['remaining'] as num).toStringAsFixed(2)
                            : '0.00',
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _projectStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.amber,
                ),
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              final isRealtimeError = error.toString().contains('RealtimeSubscribeException');
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: isRealtimeError ? Colors.orange.shade300 : Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRealtimeError 
                          ? 'Connection issue - retrying...' 
                          : 'Error loading project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _initializeStreams();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Project not found.'),
              );
            }

            final data = snapshot.data!;
            projectData = data;

            final projectDetails = data['projectDetails'] as Map<String, dynamic>?;
            if (projectDetails != null) {
              _checkChatPermission(projectDetails);
              _loadContractorData(projectDetails);
            }

            return _buildResponsiveContent();
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveContent() {
    return _buildDesktopContent();
  }

  Widget _buildDesktopContent() {
    final projectDetails = projectData!['projectDetails'] as Map<String, dynamic>? ?? projectData!;
    final projectStatus = projectDetails['status'] ?? '';

    final canMakePayment = projectStatus == 'active' && !_isPaid;
    
    return RefreshIndicator(
      onRefresh: () async {
        await _emitAggregatedData();
        await _getChatRoomId();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: CeeProjectDashboard(
            projectId: widget.projectId,
            projectData: projectData,
            createSignedPhotoUrl: createSignedPhotoUrl,
            onPayment: canMakePayment ? _handlePayment : null,
            isPaid: _isPaid,
            onViewPaymentHistory: _isPaid ? _showPaymentHistory : null,
            paymentButtonText: _paymentSummary?['payment_status'] == 'partial' ? 'Make Payment' : null,
          ),
        ),
      ),
    );
  }
}
